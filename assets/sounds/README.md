# Sound Assets

This directory contains audio feedback files for the application.

## Required Sound Files:

- `tap.mp3` - Button press feedback (50ms, subtle click)
- `success.mp3` - Scan completion success (200ms, positive tone)
- `error.mp3` - Error notification (150ms, gentle alert)
- `scan_start.mp3` - Scan initiation (100ms, camera shutter)
- `scan_complete.mp3` - Scan finished (250ms, completion chime)
- `notification.mp3` - General notifications (180ms, soft ping)

## Audio Specifications:
- Format: MP3, 192 kbps
- Duration: 50-250ms
- Volume: Normalized to -6dB peak
- Frequency: 440-880Hz range for pleasant tones

## Usage:
These audio files are played through the AudioService when haptic feedback
is enabled in settings. All sounds are optional and can be disabled by users.
