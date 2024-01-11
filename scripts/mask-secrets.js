#!/usr/bin/node
const fs = require('fs')
const yaml = require('js-yaml');

const config = {
  helmValueFile : "",
  helmValue: {},
  sopsConfigFile : ".sops.yaml",
  sopsConfig : {},
  contentFile: null

}
// print process.argv
process.argv.forEach(function (val, index, array) {
  //console.log(index + ': ' + val);
  if (index == 2) {
    try {
      if (fs.existsSync(val)) {
        config.helmValueFile = val
      }
    } catch(err) {
      console.error(err)
    }
  }
  if (index == 3) {
    try {
      if (fs.existsSync(val)) {
        config.contentFile = val
      }
    } catch(err) {
      console.error(err)
    }
  }
});

const isObject = (value) => {
  return !!(value && typeof value === "object" && !Array.isArray(value));
};

const findValuesWithKey = (object = {}, keyToMatch = "", key, result) => {
  if (isObject(object)) {
    const entries = Object.entries(object);

    for (let i = 0; i < entries.length; i += 1) {
      const [objectKey, objectValue] = entries[i];
      if (objectKey === keyToMatch) {
        result.set(key+"."+objectKey,objectValue);
      }
      if (isObject(objectValue)) {
        const child = findValuesWithKey(objectValue, keyToMatch, key+"."+objectKey, result);

        if (child !== null) {
          return child;
        }
      }
    }
  }

  return null;
};

try {
  const helmValues = yaml.safeLoad(fs.readFileSync(config.helmValueFile, 'utf8'));
  const indentedJson = JSON.stringify(helmValues, null, 4);
  const result = new Map();
  config.helmValue = helmValues;
  const sopsConfig = yaml.safeLoad(fs.readFileSync(config.sopsConfigFile, 'utf8'));
  //console.log(JSON.stringify(sopsConfig, null, 4));
  config.sopsConfig = sopsConfig;
  sopsConfig["creation_rules"].forEach(creation_rule => {
    //console.log(creation_rule.encrypted_regex);
    let secretKeys = ""+creation_rule.encrypted_regex;
    if(secretKeys.length > 4){
      secretKeys = secretKeys.substring(2, secretKeys.length-2)
      //console.log("secretKeys:",secretKeys);
      const splits = secretKeys.split('|');
      //console.log("splits:",splits);
      splits.forEach(secretKey =>{
        //console.log("secretKey:",secretKey);
        findValuesWithKey(helmValues, secretKey, "",result);      })
    }
  });
  let content = fs.readFileSync(config.contentFile, 'utf8')
  for (let [key, value] of result) {
    content = content.replace(value, "****");
  }
  fs.writeFile(config.contentFile, content, err => {
    if (err) {
      console.error(err);
    }
    //console.log("file masked successfully");
  });

} catch (e) {
  console.log(e);
}
