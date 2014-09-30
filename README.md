tabula_rasa
===========

Copyright &copy; 2014, Shlomo Swidler. All rights reserved. 
Licensed for non-commercial use only.

Run community cookbooks from within AWS OpsWorks without clashing with the older versions in [opsworks-cookbooks](https://github.com/aws/opsworks-cookbooks). Recipes run from within Tabula Rasa will not have access to the opsworks-cookbooks (unless you include them in your repository) but they will see your Custom Stack JSON and all the Ohai settings added by the AWS OpsWorks Agent.

# Usage
AWS OpsWorks has several lifecycle actions: `setup`, `configure`, `deploy`, `undeploy`, and `shutdown`. In Custom layers you can specify the custom list of recipes to run for each action. With Tabula Rasa, you specify the run list in the Custom Stack JSON, as well as the repository from which to pull the Tabula Rasa cookbooks.

Tabula Rasa repositories can support Berkshelf. Berkshelf will be invoked if the Stack Settings also enable Berkshelf for the Stack's Custom Cookbook Repository.

To use Tabula Rasa:
1. Configure your Custom Stack JSON as per the Configuration section below, to specify the repository from which the Tabula Rasa cookbooks are retrieved, and the custom run list for each OpsWorks lifecycle action.
2. Include the `tabula_rasa` recipe in the OpsWorks Layer for each lifecycle action.

# Configuration
The OpsWorks Custom Stack JSON should be used to specify the following items:

### Tabula Rasa cookbook repository
```
{ 
  "tabula_rasa": {
    "scm": {
      "type":       "git" or "svn" (s3 or other archives TBD)
      "repository": "Git or SVN URL",
      "revision":   "revision of the repo - HEAD is the default"
      "user":       "OPTIONAL - Git or SVN user"
      "password":   "OPTIONAL - Git or SVN password"
    }
  }
}
```

The repository SSH key specified in the Stack Settings will be used, if necessary, to fetch the Tabula Rasa cookbooks.

### Tabula Rasa run lists
```
{
  "tabula_rasa":
    "recipes": {
      "setup":      [ "recipe1", "cookbook::recipe2", "recipe3" ],
      "configure":  [ "recipe1", "cookbook::recipe2", "recipe3" ],
      "shutdown":   [ "recipe1" ]
    }
  }
}
```

Each entry in the `[:tabula_rasa][:recipes]` hash corresponds to the run list for that lifecycle action.
You can omit any lifecycle action that does not need a custom Tabula Rasa run list.

