      ########::::'###::::'########::'########::'####:'########:'########::'######::'########:
      ..... ##::::'## ##::: ##.... ##: ##.... ##:. ##:: ##.....:: ##.....::'##... ##:... ##..::
      :::: ##::::'##:. ##:: ##:::: ##: ##:::: ##:: ##:: ##::::::: ##::::::: ##:::..::::: ##::::
      ::: ##::::'##:::. ##: ########:: ########::: ##:: ######::: ######:::. ######::::: ##::::
      :: ##::::: #########: ##.....::: ##.....:::: ##:: ##...:::: ##...:::::..... ##:::: ##::::
      : ##:::::: ##.... ##: ##:::::::: ##::::::::: ##:: ##::::::: ##:::::::'##::: ##:::: ##::::
       ########: ##:::: ##: ##:::::::: ##::::::::'####: ##::::::: ########:. ######::::: ##::::
      ........::..:::::..::..:::::::::..:::::::::....::..::::::::........:::......::::::..:::::


Cli app to generate Zapp plugin manifest.

#### Installation

Install via Homebrew  
```bash
brew tap applicaster/tap 
brew install zappifest 
```

#### Upgrade
```bash
brew update 
brew upgrade zappifest 
```

## Usage
### Init
Zappifest allows fast configuration for Zapp plugin-manifest.json file.  
Just run `zappifest init` and follow the instructions.

### Publish
The tool allow you to publish the plugin to Zapp.
`run zappifest publish --manifest <path_to_manifest-json-file> --access-token <zapp-access-token>`




