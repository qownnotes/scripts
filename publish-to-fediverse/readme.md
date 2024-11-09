## Overview

The **Publish To Fediverse** script for QOwnNotes allows users to publish markdown notes directly to their Mastodon-*tish* activitypub servers. This means that this *should* work with servers that implemente the same APIs as Mastodon, like GoToSocial (the script project started from **publish-to-GoToSocial**). If you happen to test the script with other servers, let me know!

Future versions will be also able to download and edit already published posts, to keep them as notes or to use other script for publishing them as standalone websites.

## Manual Installation

1. **Download the Plugin**: Save the `publish-to-fediverse.qml`  file to your local machine.
2. **Add to QOwnNotes**:
   - Open QOwnNotes.
   - Navigate to `Settings` > `Scripting`.
   - Click on `Add script... > Add local script`.
   - Select the  `publish-to-fediverse.qml` file in the script folder.
3. **Activate the Plugin**:
   - Go back to QOwnNotes.
   - In the `Scripting` settings, ensure that  `publish-to-fediverse.qml` is listed and checked.

## Settings

- **Server instance**: Server instance you want to connect to (i.e.: example.org - no spaces, no protocol, no slashes);
- **Authentication Code**: Code returned by GtS after performing a successful authentication, or by requesting it from your instance settings page, if you paste it here you won't need to authenticate again until expiry or revocation;
- **Post Signature**: This is a signature that will be appended to your posts.
- **Visibility**: Default visibility for published posts:
  - Public
  - Unlisted
  - Private
  - Mutuals (not supported by Mastodon)
  - Direct Message
- **Local Only**: If the post is local only, it will not be seen from federated instances (not supported by Mastodon);
- **Content Warning**: The post text will not be immediately visible, as it may be sensible to some audience;
- **Content Warning text**: Text to show as a content warning for senstitive posts: this should be used **only** if the *Content Warning* is checked, _leave this field empty if yout wan an undisclosed post_;
- **Language code**: 2-chars laguage code as per https://www.loc.gov/standards/iso639-2/php/English_list.php.

## Usage

After installation type the server instance name on the script settings and press Ok. Connection with your server will be established the first time you will publish a post.

There are two implemented use cases:
1. **Creation of a new note**
2. **Note publishing**

### Creation of a new note

1. Select `Custom actions > New Post for GtS` on the context menu **or** click on `Scripting > Custom actions > New post for Fediverse`;
2. A new note with default Post Header will be created
3. Write your post below the front matter, adjust the post settings as per your preferences. You can try to add other accepted parameters and they should work, but it's not a supported feature. Not sure for nested object parameters. 

### Note publishing for first access

Here the process splits, depending on the authentication mechanism your instance has in place.
#### For Mastodon
1. Head to the Settings page at your instance and look for `<> Development`
2. Click on `New Application' and fill the form entering:
  - Application name: `QONP2F`
  - Redirect URI: ensure it is set to `urn:ietf:wg:oauth:2.0:oob`
  - Scopes: check`Read`, `Write` and `Profile`
3. Confirm and save the changes
4. Copy the freshly generated `Your access token` value and paste it in the Script setting `Authorization Code` on QON.

#### For GoToSocial
1. On the note to be published right click and select `Custom actions > Publish current note to Fediverse`
2. A dialog pops out, summarizing the post settings and asking for confirmation. Press Ok.
3. If this is the first note published an input dialog pops out: open the link referenced in the popup on your browser (you may need to copy and paste it depending on your OS settings). Keep the popup opened.
4. Perform the authentication on your browser with the user you want to impersonate and click on *"Allow"* in the confirmation page
5. Copy the Authentication code from the web page, paste it back to the popup and press "Ok".
6. Another popup will open asking to copy the Authorization code to your script settings pages, on the `Authorization Code` field.
6. The post gets published with current settings.

#### Other Note publishing details

A published note gains extra information on the front matter:
- a **created_at** datatime field, that is returned by your server
- an **id** as the published post id
- an **url** as the published post permalink

A published note also gains 2 note tags:
- a `P2F` tag to identify the post as managed and modified by the publish-to-gts script
- a `Published` tag to identify a note that has been already published

In case you try to publish a note that contains `created_at` in the front matter a confirmation will be requested. If confirmed the post will be published again, updating the `created_at` datetime and the `id` and `url`, as GtS do not provide yet a post editing feature.

In case you try to publish a note that does not contain the front matter, a front matter will be generated at the moment and updated when the note is published.

## Contributing

If you have suggestions or improvements, feel free to fork the repository and submit a pull request.

## Needed testers on MacOS!

## ToDo

- [x] ~Create a publishing dialog with post options~ Options added to script settings, some confirmation dialogs added;
- [x] Add custom tags to posts with post header section and to those that have already been published, in order to avoid reposting;
- [ ] Support media attachments to notes (actually not supported);
- [x] Add a post signature feature to automatically add markdown-enriched signature to your posts
- [ ] Add support for QON tags associated with the note being published as actual hashtags on the post
- [ ] Start working on the download posts feature...

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

Enjoy using the Publish To Fediverse script to enhance your social publishing experience with QOwnNotes!