# Example NodeJS Provider - Postman

<!-- Build Badge -->

[![Build Status](https://github.com/pactflow/example-bi-directional-provider-postman/actions/workflows/build.yml/badge.svg)](https://github.com/pactflow/example-bi-directional-provider-postman/actions)

<!-- Can I Deploy Badge -->

[![Can I deploy Status](https://testdemo.pactflow.io/pacticipants/pactflow-example-bi-directional-provider-postman/branches/master/latest-version/can-i-deploy/to-environment/production/badge)](https://testdemo.pactflow.io/pacticipants/pactflow-example-bi-directional-provider-postman/branches/master/latest-version/can-i-deploy/to-environment/production/badge)


- [Example NodeJS Provider - Postman](#example-nodejs-provider---postman)
  - [Overview of Example](#overview-of-example)
    - [Key points](#key-points)
  - [Overview of Part of Bi-Directional Contract Testing Flow](#overview-of-part-of-bi-directional-contract-testing-flow)
  - [Compatibile with Consumers](#compatibile-with-consumers)
  - [Pre-requisites](#pre-requisites)
    - [Environment variables](#environment-variables)
  - [Usage](#usage)
    - [Steps](#steps)
  - [OS/Platform specific considerations](#osplatform-specific-considerations)
    - [Windows](#windows)
  - [Caveats](#caveats)
  - [Related topics / posts / discussions](#related-topics--posts--discussions)
  - [Other examples of how to do this form of testing](#other-examples-of-how-to-do-this-form-of-testing)
  - [Found an issue?](#found-an-issue)

## Overview of Example

<!-- Provider Overview -->

This is an example of a NodeJS "Product" API Provider that uses Postman, Pact, [Pactflow](https://pactflow.io) and GitHub Actions to generate and publish Pact provider contracts.

It performs pre-deployment cross-compatability checks to ensure that it is compatible with specified consumers using the Bi-Directional contract capability of Pactflow.

<!-- General -->

See the full [Pactflow Bi-Directional Workshop](https://docs.pactflow.io/docs/workshops/bi-directional-contract-testing) for which this can be substituted in as the "provider".

### Key points

It:

- Is an API written in Express JS
- Has a Postman 2.1 collection (see `./test/PactflowProductsAPI.postman_collection.json`)
- Uses Newman to test the API against the postman collection
- Uses [Postman2OpenAPI](https://github.com/kevinswiber/postman2openapi) to convert a Postman collection to an OAS for use in the bi-directional contracts feature.

What is uploaded to Pactflow is an OpenAPI specification that represents what you actually tested with Postman, to give us confidence it is compatible with a Pact consumer.

## Overview of Part of Bi-Directional Contract Testing Flow

<!-- Provider Overview -->

In the following diagram, you can see how the provider testing process works.

When we call "can-i-deploy" the cross-contract validation process kicks off on Pactflow, to ensure any consumer consumes a valid subset of the OAS for the provider.

![Provider Test](docs/provider-scope.png "Provider Test")

The project uses a Makefile to simulate a very simple build pipeline with two stages - test and deploy.

When you run the CI pipeline (see below for doing this), the pipeline should perform the following activities (simplified):

* Test
  * Run tests to check spec compliance with openAPI spec
  * Create branch tag via Pact CLI
  * Publish openAPI spec, along with a version with the name of the current branch
  * Check if we are safe to deploy to Production with `can-i-deploy` (ie. has the cross-contract validation has been successfully performed)
* Deploy (only from <main|master>)
  * Deploy app to Production
  * Record the Production deployment in the Pact Broker
  * 

![Provider Pipeline](docs/provider-pipeline.png "Provider Pipeline")


## Compatibile with Consumers

<!-- Consumer Compatability -->

This project is currently compatible with the following consumers(s):

* [pactflow-example-bi-directional-consumer-nock](https://github.com/pactflow/example-bi-directional-consumer-nock)
* [pactflow-example-bi-directional-consumer-msw](https://github.com/pactflow/example-bi-directional-consumer-msw)
* [pactflow-example-bi-directional-consumer-wiremock](https://github.com/pactflow/example-bi-directional-consumer-wiremock)
* [pactflow-example-bi-directional-consumer-mountebank](https://github.com/pactflow/example-bi-directional-consumer-mountebank)
<!-- * [pactflow-example-bi-directional-consumer-dotnet](https://github.com/pactflow/example-bi-directional-consumer-dotnet) -->


See [Environment variables](#environment-variables) on how to set these up
  

## Pre-requisites

**Software**:

- Tools listed at: https://docs.pactflow.io/docs/workshops/ci-cd/set-up-ci/prerequisites/
- A pactflow.io account with an valid [API token](https://docs.pactflow.io/docs/getting-started/#configuring-your-api-token)

### Environment variables

To be able to run some of the commands locally, you will need to export the following environment variables into your shell:

- `PACT_BROKER_TOKEN`: a valid [API token](https://docs.pactflow.io/docs/getting-started/#configuring-your-api-token) for Pactflow
- `PACT_BROKER_BASE_URL`: a fully qualified domain name with protocol to your pact broker e.g. https://testdemo.pactflow.io

## Usage

### Steps

- `make test` - run the newman testing suite
- `make convert` - converts the Postman collection to an OAS for bi-directional contract (automatically done by the `make fake_ci` step)
- `make fake_ci` - run the CI process, but locally

## OS/Platform specific considerations

The makefile is configured to run on Unix based systems such as you would find in most common CI/CD pipelines. 

They can be run locally on Unix/Mac, or on Windows via [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install). 

### Windows 

You can still try this example locally on Windows using powershell and running commands manually. 

<details>
  <summary>Click to see windows specific instructions here</summary>


  These will be the same commands that are used in the makefile with a few manual tweaks.

1. Make sure you have set all of the environment variables, in powershell they can be set like so.

    ```
     $env:GIT_BRANCH="main"
    ```

  1. Publish the pact that was generated. The step uses the pact-cli docker image to publish the pact to your pactflow account.
  The path for `<path_to_project_root>` needs to be converted from Windows paths to UNIX ones as the Docker container is using UNIX. Either hard code this or set it as another environment variable.

      `C:\Users\Person\Documents\example-bi-directional-consumer-dotnet` 
      
      becomes
      
      `/c/Users/Candy/Documents/Pactflow/example-bi-directional-consumer-dotnet`

      $env:VARIABLE_NAME refers to the environment variables in windows.

      ```
      docker run --rm -v <path_to_project_root>:<path_to_project_root> -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli publish <path_to_pacts_folder> --consumer-app-version $env:GIT_COMMIT --tag $env:GIT_BRANCH

      ```

  4. Check can-i-deploy to see if your provider is compatible with your pact.

      ```
      docker run --rm -v <path_to_project_root>:<path_to_project_root> -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli  broker can-i-deploy --pacticipant pactflow-example-bi-directional-consumer-dotnet --version $env:GIT_COMMIT --to-environment production  --retry-while-unknown 0 --retry-interval 10
      ```

5. Have a look at what other commands are available in the Makefile. All of them can be ran locally from Powershell by changing the windows paths to UNIX and replacing the environment variable references. Any variable referenced as `${VARIABLE}` can be changed to `$env:VARIABLE` to reference environment variables in Powershell.

</details>


## Caveats

1. OAS is generated by the examples attached to each request. If there are mulitple overlapping paths, the last one will clobber earlier ones (use the Postman examples feature to overcome this)
2. Postman tests are attached to the "item" level, not the examples. So it's possible to put in examples that don't actually match reality and aren't tested.

## Related topics / posts / discussions

- TBC

## Other examples of how to do this form of testing

- TBC

## Found an issue?

Reach out via a GitHub Issue, or reach us over in the [Pact foundation Slack](https://slack.pact.io)
