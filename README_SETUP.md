# Setup Instructions

## Firebase Configuration

1. Download `GoogleService-Info.plist` from your Firebase Console
2. Place it in the root of the `frontend` directory
3. The file should **NOT** be committed to git (it's in `.gitignore`)

You can use `GoogleService-Info.plist.example` as a reference for the structure.

## Important Security Notes

⚠️ **Never commit `GoogleService-Info.plist` to version control!**

This file contains sensitive API keys and credentials. If you accidentally committed it:
1. Remove it from git tracking: `git rm --cached GoogleService-Info.plist`
2. Rotate your API keys in Firebase Console
3. Update the keys in your local `GoogleService-Info.plist` file

