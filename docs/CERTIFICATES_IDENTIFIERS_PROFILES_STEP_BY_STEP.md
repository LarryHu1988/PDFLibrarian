# Distribution signing

Bundle ID: `com.larry.pdflibrarian` · Team: `2S7X36GQC9`

Mac App Store uploads use an Apple Distribution identity, a matching Mac App Store provisioning profile, and a Mac Installer Distribution identity. `scripts/package_app_store_cli.py` signs through a temporary keychain and never changes the login keychain.

Direct downloads use a distinct Developer ID Application identity with hardened runtime, secure timestamps, and Apple notarization. `scripts/package_developer_id.py` creates the signed ZIP in a non-iCloud staging folder to avoid Finder resource attributes. Staple accepted tickets before final ZIP/DMG packaging.

Keep private keys, passwords, profiles, and API credentials outside this repository. Public certificate metadata and package checks belong in local release evidence, not README download claims.
