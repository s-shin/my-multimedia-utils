# my-multimedia-utils

```sh
# uconv command required.
brew install icu4c
export PATH="/usr/local/opt/icu4c/bin:$PATH"

# Example
./bin/my-music-mgr diff "${HOME}/Music/iTunes/iTunes Media/Music" /storage/0000-0000/Music --dst-android
```

## Music Directory Structure

```
Music/
    # Album directory path
    <artist>/
        # Album directory
        <album>
        # or album archive
        <album>.tar
```
