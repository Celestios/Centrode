import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class InitErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final VoidCallback? onShowDetails;

  const InitErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: UiInsets.gutter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: UiSpacing.gutter),
              const Text(
                'Failed to Initialize Database',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: UiSpacing.standard),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: UiSpacing.gutter),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              if (onShowDetails != null) ...[
                const SizedBox(height: UiSpacing.container),
                TextButton(
                  onPressed: onShowDetails,
                  child: const Text('Show Details'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
