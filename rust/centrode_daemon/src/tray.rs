pub fn init_tray() -> anyhow::Result<()> {
    tracing::info!("Tray: system tray placeholder (requires platform-specific event loop)");
    Ok(())
}
