# Android Keystore Setup

This guide will help you create and configure an Android keystore for signing your APK files in GitHub Actions.

## Why do you need a keystore?

A keystore is a secure file that contains cryptographic keys used to digitally sign your Android application. Android requires all apps to be signed before they can be installed on a device. Without a properly signed APK, users won't be able to install your app.

## Step 1: Generate Keystore

Run this command in your terminal (requires Java JDK):

```bash
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias flowvy
```

You'll be asked to provide:
- **Keystore password**: Choose a strong password (save it securely!)
- **Key password**: Can be the same as keystore password or different
- **Your name and organization details**: Fill as needed

**Important:** Save the passwords somewhere safe! You'll need them for GitHub Secrets and if you ever need to update your app.

## Step 2: Encode Keystore to Base64

After creating `keystore.jks`, encode it to base64:

**On Windows (PowerShell):**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("keystore.jks")) | Out-File -Encoding ASCII keystore.base64.txt
```

**On Linux/macOS:**
```bash
base64 keystore.jks > keystore.base64.txt
```

This will create `keystore.base64.txt` containing the encoded keystore.

## Step 3: Set up GitHub Secrets

Go to your GitHub repository:
1. Click **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** and add these 4 secrets:

| Secret Name | Value | Where to get it |
|------------|--------|----------------|
| `KEYSTORE` | Content of `keystore.base64.txt` | Open the file and copy entire content |
| `KEY_ALIAS` | `flowvy` | The alias you used in keytool command |
| `STORE_PASSWORD` | Your keystore password | Password you entered when creating keystore |
| `KEY_PASSWORD` | Your key password | Password for the key (usually same as store password) |

**Screenshot guide:**
- Settings → Secrets and variables → Actions → New repository secret
- Paste the name and value
- Click "Add secret"

## Step 4: Test the Setup

1. Create a git tag (e.g., `v1.0.0`) and push it:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. GitHub Actions will automatically start building Android and Windows versions

3. Check the Actions tab in your repository to see the build progress

4. Once complete, a new release will be created with the APK and Windows installers

## Security Notes

- **Never commit `keystore.jks` to git!** It's already in `.gitignore`
- Keep `keystore.base64.txt` secure and delete it after uploading to GitHub
- Store your keystore file and passwords in a safe place (password manager, encrypted backup)
- If you lose the keystore, you won't be able to update your app on users' devices

## Troubleshooting

**"keytool: command not found"**
- Install Java JDK (Java Development Kit)
- On Windows: Download from [Oracle](https://www.oracle.com/java/technologies/downloads/) or use `winget install Oracle.JDK.21`

**"Build failed: signing config not found"**
- Double-check that all 4 GitHub Secrets are set correctly
- Make sure there are no extra spaces in the secret values

**"Invalid keystore format"**
- Re-encode the keystore to base64
- Make sure you copied the entire content of `keystore.base64.txt`
