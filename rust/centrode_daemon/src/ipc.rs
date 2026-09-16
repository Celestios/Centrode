use anyhow::{Context, Result};
use serde::{de::DeserializeOwned, Serialize};
use std::io::{Read, Write};

pub const IPC_PIPE_NAME: &str = r"\\.\pipe\centrode-custodian-ipc";

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
#[serde(tag = "method", content = "params")]
pub enum IpcMessage {
    OpenMap {
        map_id: String,
        map_name: Option<String>,
        cent_file_path: Option<String>,
    },
    YieldBaton {
        target_process: String,
    },
    FocusWindow,
    Ping,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct IpcResponse {
    pub success: bool,
    pub active_state: String,
    pub message: Option<String>,
}

fn write_frame<W: Write>(writer: &mut W, payload: &[u8]) -> Result<()> {
    let len = payload.len() as u32;
    writer.write_all(&len.to_be_bytes())?;
    writer.write_all(payload)?;
    writer.flush()?;
    Ok(())
}

fn read_frame<R: Read>(reader: &mut R) -> Result<Vec<u8>> {
    let mut len_buf = [0u8; 4];
    reader.read_exact(&mut len_buf)?;
    let len = u32::from_be_bytes(len_buf) as usize;

    let mut payload = vec![0u8; len];
    reader.read_exact(&mut payload)?;
    Ok(payload)
}

pub fn send_message<W: Write, M: Serialize>(writer: &mut W, msg: &M) -> Result<()> {
    let json = serde_json::to_vec(msg).context("IPC: failed to serialize message")?;
    write_frame(writer, &json)
}

pub fn recv_message<R: Read, M: DeserializeOwned>(reader: &mut R) -> Result<M> {
    let payload = read_frame(reader).context("IPC: failed to read frame")?;
    serde_json::from_slice(&payload).context("IPC: failed to deserialize message")
}

pub struct IpcClient {
    pipe_name: String,
}

impl IpcClient {
    pub fn new(pipe_name: impl Into<String>) -> Self {
        Self {
            pipe_name: pipe_name.into(),
        }
    }

    pub fn connect_and_send<M: Serialize, R: DeserializeOwned>(&self, msg: &M) -> Result<R> {
        #[cfg(target_os = "windows")]
        {
            use interprocess::local_socket::prelude::*;
            use interprocess::local_socket::{GenericNamespaced, ToNsName};
            let name = self
                .pipe_name
                .as_str()
                .to_ns_name::<GenericNamespaced>()
                .context("IPC: invalid pipe name")?;
            let mut stream = LocalSocketStream::connect(name)
                .context("IPC: failed to connect to pipe")?;
            send_message(&mut stream, msg)?;
            recv_message(&mut stream)
        }
        #[cfg(not(target_os = "windows"))]
        {
            use std::os::unix::net::UnixStream;
            let stream = UnixStream::connect(self.pipe_name.as_str())
                .context("IPC: failed to connect to UDS")?;
            let mut stream = stream;
            send_message(&mut stream, msg)?;
            recv_message(&mut stream)
        }
    }
}

pub struct IpcServer {
    pipe_name: String,
}

impl IpcServer {
    pub fn new(pipe_name: impl Into<String>) -> Self {
        Self {
            pipe_name: pipe_name.into(),
        }
    }

    pub fn serve<F>(&self, handler: F) -> Result<()>
    where
        F: Fn(IpcMessage) -> IpcResponse,
    {
        #[cfg(target_os = "windows")]
        {
            use interprocess::local_socket::prelude::*;
            use interprocess::local_socket::{GenericNamespaced, ListenerOptions, ToNsName};
            let name = self
                .pipe_name
                .as_str()
                .to_ns_name::<GenericNamespaced>()
                .context("IPC: invalid pipe name")?;
            let listener = ListenerOptions::new()
                .name(name)
                .create_sync()
                .context("IPC: failed to bind named pipe")?;
            loop {
                match listener.accept() {
                    Ok(mut stream) => {
                        if let Ok(msg) = recv_message(&mut stream) {
                            let resp = handler(msg);
                            let _ = send_message(&mut stream, &resp);
                        }
                    }
                    Err(e) => {
                        tracing::warn!("IPC: connection error: {}", e);
                    }
                }
            }
        }
        #[cfg(not(target_os = "windows"))]
        {
            use std::os::unix::net::UnixListener;
            let listener =
                UnixListener::bind(self.pipe_name.as_str()).context("IPC: failed to bind UDS")?;
            loop {
                match listener.accept() {
                    Ok((mut stream, _)) => {
                        if let Ok(msg) = recv_message(&mut stream) {
                            let resp = handler(msg);
                            let _ = send_message(&mut stream, &resp);
                        }
                    }
                    Err(e) => {
                        tracing::warn!("IPC: connection error: {}", e);
                    }
                }
            }
        }
    }

    pub fn accept_one<F>(&self, handler: &F) -> Result<()>
    where
        F: Fn(IpcMessage) -> IpcResponse,
    {
        #[cfg(target_os = "windows")]
        {
            use interprocess::local_socket::prelude::*;
            use interprocess::local_socket::{GenericNamespaced, ListenerOptions, ToNsName};
            let name = self
                .pipe_name
                .as_str()
                .to_ns_name::<GenericNamespaced>()
                .context("IPC: invalid pipe name")?;
            let listener = ListenerOptions::new()
                .name(name)
                .create_sync()
                .context("IPC: failed to bind named pipe")?;
            let mut stream = listener.accept().context("IPC: failed to accept")?;
            let msg: IpcMessage = recv_message(&mut stream)?;
            tracing::debug!("IPC: received {:?}", msg);
            let resp = handler(msg);
            send_message(&mut stream, &resp)?;
        }
        #[cfg(not(target_os = "windows"))]
        {
            use std::os::unix::net::UnixListener;
            let listener =
                UnixListener::bind(self.pipe_name.as_str()).context("IPC: failed to bind UDS")?;
            let (mut stream, _) = listener.accept().context("IPC: failed to accept")?;
            let msg: IpcMessage = recv_message(&mut stream)?;
            tracing::debug!("IPC: received {:?}", msg);
            let resp = handler(msg);
            send_message(&mut stream, &resp)?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ipc_message_roundtrip() {
        let msg = IpcMessage::OpenMap {
            map_id: "abc123".into(),
            map_name: Some("My Map".into()),
            cent_file_path: None,
        };
        let json = serde_json::to_vec(&msg).unwrap();
        let decoded: IpcMessage = serde_json::from_slice(&json).unwrap();
        match decoded {
            IpcMessage::OpenMap { map_id, .. } => assert_eq!(map_id, "abc123"),
            _ => panic!("wrong variant"),
        }
    }

    #[test]
    fn test_ipc_response_roundtrip() {
        let resp = IpcResponse {
            success: true,
            active_state: "daemon".into(),
            message: None,
        };
        let json = serde_json::to_vec(&resp).unwrap();
        let decoded: IpcResponse = serde_json::from_slice(&json).unwrap();
        assert!(decoded.success);
        assert_eq!(decoded.active_state, "daemon");
    }

    #[test]
    fn test_frame_length_prefixing_and_roundtrip() {
        let payload = b"hello centrode ipc payload";
        let mut buffer = Vec::new();
        write_frame(&mut buffer, payload).unwrap();

        // Verify 4-byte big-endian length prefix
        assert_eq!(buffer.len(), 4 + payload.len());
        let len_prefix = u32::from_be_bytes([buffer[0], buffer[1], buffer[2], buffer[3]]) as usize;
        assert_eq!(len_prefix, payload.len());
        assert_eq!(&buffer[4..], payload);

        // Verify read_frame reads from Cursor
        let mut cursor = std::io::Cursor::new(buffer);
        let decoded = read_frame(&mut cursor).unwrap();
        assert_eq!(decoded, payload);
    }

    #[test]
    fn test_frame_empty_payload() {
        let payload = b"";
        let mut buffer = Vec::new();
        write_frame(&mut buffer, payload).unwrap();

        assert_eq!(buffer.len(), 4);
        assert_eq!(buffer, [0, 0, 0, 0]);

        let mut cursor = std::io::Cursor::new(buffer);
        let decoded = read_frame(&mut cursor).unwrap();
        assert!(decoded.is_empty());
    }

    #[test]
    fn test_frame_partial_and_truncated_reads() {
        // Truncated length header (less than 4 bytes)
        let partial_header = vec![0u8, 0u8, 1u8];
        let mut cursor = std::io::Cursor::new(partial_header);
        assert!(read_frame(&mut cursor).is_err());

        // Header claims 16 bytes, but cursor only contains 5 bytes
        let mut truncated_stream = 16u32.to_be_bytes().to_vec();
        truncated_stream.extend_from_slice(b"12345");
        let mut cursor = std::io::Cursor::new(truncated_stream);
        assert!(read_frame(&mut cursor).is_err());
    }
}
