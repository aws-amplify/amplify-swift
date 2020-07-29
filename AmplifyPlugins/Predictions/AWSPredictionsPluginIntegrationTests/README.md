#  AWSPredictionsPluginIntegrationTests

The following steps demonstrate how to set up DataStore with a conflict resolution enabled API through amplify CLI, with API key authentication mode. 

### Set-up

1. `amplify init` and choose `iOS` for type of app you are building

2. `amplify add predictions` to add `Identify Labels` function

```perl
? Please select from one of the categories below `Identify`
? You need to add auth (Amazon Cognito) to your project in order to add storage 
for user files. Do you want to add auth now? `Yes`
? Do you want to use the default authentication and security configuration? `Default configuration`
? How do you want users to be able to sign in? `Username`
? Do you want to configure advanced settings? `No, I am done`
? What would you like to identify? `Identify Labels`
? Provide a friendly name for your resource `yourResourceName`
? Would you like use the default configuration? `Default configuration`
? Who should have access? `Auth and Guest users`
```

3. `amplify add predictions` to add `Identify Entities` function

```perl
? Please select from one of the categories below `Identify`
? What would you like to identify? `Identify Entities`
? Provide a friendly name for your resource `yourResourceName`
? Would you like use the default configuration? `Default configuration`
? Who should have access? `Auth and Guest users`
```

4. `amplify add predictions` to add `Identify Text` function

```perl
? Please select from one of the categories below `Identify`
? What would you like to identify? `Identify Text`
? Provide a friendly name for your resource `yourResourceName`
? Would you also like to identify documents? `Yes`
? Who should have access? `Auth and Guest users`
```

5. `amplify add predictions` to add `interpret text` function

```perl
? Please select from one of the categories below `Interpret`
? What would you like to interpret? `Interpret Text`
? Provide a friendly name for your resource `yourResourceName`
? What kind of interpretation would you like? `All`
? Who should have access? `Auth and Guest users`
```

6. `amplify add predictions` to add `convert speech to text` function

```perl
? Please select from one of the categories below `Convert`
? What would you like to convert? `Transcribe text from audio`
? Provide a friendly name for your resource `yourResourceName`
? What is the source language? `US English`
? Who should have access? `Auth and Guest users`
```
Notice when provisioning resource for speech conversion, we are using `Amazon Transcribe (real-time streaming)` which is not supported on every region.
You can simply change the `region` inside `convert` block to the supported region code
Example: `eu-west-2` doesn't support `Amazon Transcribe (real-time streaming)` so that you can change it to `eu-west-1` where supports the service
You can find the information in [Region Table](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/) 

7. `amplify push`

8. Copy `amplifyconfiguration.json` over to the `Configuration` folder

You should now be able to run all of the tests 

### Images used for integration tests:

1. testImageText.jpg [sketchbook-comp-4-text-and-image](https://mir-s3-cdn-cf.behance.net/project_modules/disp/44ccbf15338381.5628facc26f03.jpg) by [Ana Curado e Silva](https://www.behance.net/gallery/15338381/Sketchbook-Comp-4-Text-and-Image) is licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/?ref=ccsearch) ![](https://search.creativecommons.org/static/img/cc_icon.svg)![](https://search.creativecommons.org/static/img/cc-by_icon.svg)![](https://search.creativecommons.org/static/img/cc-nc_icon.svg)![](https://search.creativecommons.org/static/img/cc-nd_icon.svg)
2. testImageCeleb.jpg [celebrities and politicians](https://mir-s3-cdn-cf.behance.net/project_modules/disp/fdd0b142234581.560716afcda7d.jpg) by [William Coupon](https://www.behance.net/gallery/5346285/celebrities-politicians) is licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/?ref=ccsearch&atype=html) ![](https://search.creativecommons.org/static/img/cc_icon.svg) ![](https://search.creativecommons.org/static/img/cc-by_icon.svg) ![](https://search.creativecommons.org/static/img/cc-nc_icon.svg) ![](https://search.creativecommons.org/static/img/cc-nd_icon.svg)
3. testimageTextAll.jpg [amazon-textract-code-samples-files](https://raw.githubusercontent.com/aws-samples/amazon-textract-code-samples/master/src-csharp/test-files/employmentapp.png)