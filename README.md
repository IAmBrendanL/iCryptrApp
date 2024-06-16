# iCryptr
An iOS app that performs AES256 encryption on device utilizing Apple's [CommonCrypto](https://opensource.apple.com/source/CommonCrypto/) encryption library written in C.

The app allows users to pick files from the Files app or photos/videos from the Photos app and encrypts them in custom file format.



#### Note
This is a complete overhaul of my original [iCryptr](https://github.com/IAmBrendanL/iCryptr) project which was a document-based app that could not handle large files.


#### RoadMap
- [x] Get basic UI set up
- [x] Rework original in-memory encryption service to work with streams
- [x] Get file encryption/decryption working
- [x] Add file thumbnail to encryption/decyption view
- [x] Write README
- [ ] Get photo encryption working 
  - (I need to see if I can get the Swift UI photo picker to not load large files into memory)
- [ ] Document the current file format in the README (rather than just in the comments)
- [ ] Add functionality to save (really move) the encrypted file to a different folder
- [ ] Add a progress indicator to the encyption/decryption page
- [ ] Consider adding a checksum of the original file to encrypted file format to verify that decryption was performed successfully
- [ ] Add a F.A.Q page that pops up when the `?` button is tapped on the home page.
