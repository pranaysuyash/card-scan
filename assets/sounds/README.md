# Sound Assets

This directory should contain the following sound effect files:

## Required Sound Files

1. **tap.mp3** - Subtle button press sound (played at 0.3 volume)
   - Duration: ~50-100ms
   - Use case: Button taps, UI interactions

2. **success.mp3** - Scan completion success sound (played at 0.6 volume)
   - Duration: ~200-500ms
   - Use case: Successful card scan, contact saved

3. **error.mp3** - Error notification sound (played at 0.8 volume)
   - Duration: ~200-400ms
   - Use case: Scan failures, validation errors

4. **scan_start.mp3** - Scan initiation sound (played at 0.6 volume)
   - Duration: ~100-200ms
   - Use case: When user initiates a card scan

5. **scan_complete.mp3** - Scan finished sound (played at 0.6 volume)
   - Duration: ~200-400ms
   - Use case: OCR processing complete

6. **notification.mp3** - General notifications sound (played at 0.4 volume)
   - Duration: ~150-300ms
   - Use case: General app notifications

## Notes

- All sounds should be MP3 format
- Keep file sizes small (<50KB per file)
- The app will function normally without these files (graceful degradation)
- Sound effects can be toggled on/off in app settings
- Consider using royalty-free sound libraries or tools like:
  - freesound.org
  - zapsplat.com (free tier)
  - Generate using tools like Audacity or online sound generators

## Recommendations

For a professional feel:
- Use subtle, pleasant tones
- Avoid jarring or loud sounds
- Test on actual devices for volume levels
- Consider accessibility (don't rely solely on sound for feedback)
