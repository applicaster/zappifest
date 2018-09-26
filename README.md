      ########::::'###::::'########::'########::'####:'########:'########::'######::'########:
      ..... ##::::'## ##::: ##.... ##: ##.... ##:. ##:: ##.....:: ##.....::'##... ##:... ##..::
      :::: ##::::'##:. ##:: ##:::: ##: ##:::: ##:: ##:: ##::::::: ##::::::: ##:::..::::: ##::::
      ::: ##::::'##:::. ##: ########:: ########::: ##:: ######::: ######:::. ######::::: ##::::
      :: ##::::: #########: ##.....::: ##.....:::: ##:: ##...:::: ##...:::::..... ##:::: ##::::
      : ##:::::: ##.... ##: ##:::::::: ##::::::::: ##:: ##::::::: ##:::::::'##::: ##:::: ##::::
       ########: ##:::: ##: ##:::::::: ##::::::::'####: ##::::::: ########:. ######::::: ##::::
      ........::..:::::..::..:::::::::..:::::::::....::..::::::::........:::......::::::..:::::


Cli app to generate and publish Zapp plugin manifest.

#### Installation

Install via Homebrew
```bash
brew tap applicaster/tap
brew install zappifest
```

#### Upgrade
```bash
brew upgrade zappifest
```

## Usage
### Init
Zappifest allows fast configuration for Zapp plugin-manifest.json file.
Just run `zappifest init` and follow the instructions.

### Publish

#### Prerequisites
Reach Applicaster support team to generate User access-token.

The tool allow you to publish the plugin to Zapp.

Run `zappifest publish --manifest <path-to-manifest-json-file> --access-token <zapp-access-token>`
If you want to publish a manifest for a new plugin, with a new identifier, you need to use the `--new` option.
This isn't needed when you are publishing a new version or updating an existing version of an existing plugin.

```
Note: It is recommended to set the access-token as environment variable `ZAPP_TOKEN`.
By doing so, `access_token` param for publishing will not be required.
```

#### Updating existing plugin
Check the plugin id on [Zapp](https://zapp.applicaster.com/admin/plugins) (under the relevant plugin versions).

Run `zappifest publish --plugin-id <plugin-id> --manifest <path-to-manifest-json-file> --access-token <zapp-access-token>`

#### Markdown files
You can use markdown files to populate the `guide` and `description` fields of the manifest. To do so, create markdown files for these fields, and add the path to these files in the command :
```
$ zappifest publish --manifest <path-to-manifest-json-file> --access-token <zapp-access-token> --plugin-about <path-to-about.md>
```

### Overriding endpoint
You can override the remote end point using `--override-url http://localhost:{your-port}/api/v1/admin`

### Contributing
1. `git clone https://github.com/applicaster/zappifest.git`
2. `cd zappifest`
3. `bundle exec bundle install`
4. `git checkout -b <your-branch>`
5. Publish with your local changes `ruby lib/zappifest.rb publish ....`
6. Push branch to remote
7. Create PR
