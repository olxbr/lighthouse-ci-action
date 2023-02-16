# lighthouse-ci-action
This composite action uses the [treosh/lighthouse-ci-action](https://github.com/treosh/lighthouse-ci-action) to collect **Core Web Vitals metrics** from frontend projects and then posts a comment on the corresponding Pull Request that ran the workflow, reporting these metrics.

## Features
- All the features by [treosh/lighthouse-ci-action](https://github.com/treosh/lighthouse-ci-action)
- Print beautiful results in workflow summary
- Comment results in Pull Request


**Workflow Summary**
![workflow-summary](https://user-images.githubusercontent.com/4138825/218758369-6e655782-75d9-42de-ae3a-e0724c4ba16b.png)

**Pull Request Comment**
![pull-request-comment](https://user-images.githubusercontent.com/4138825/218758644-96ada0aa-bb2b-4392-acab-9ed875560d4e.png)

## Prerequisites
Before using this action, please ensure the following:

- Your frontend project is set up and running, with an accessible URL that you can use to run Lighthouse-CI.
- If you want to use a self-hosted runner, you need to [set up Chrome browser](https://github.com/browser-actions/setup-chrome) and set `--headless --disable-storage-reset --disable-dev-shm-usage` parameters.

## Usage

```yml
- name: Run Lighthouse
        id: lhci-action
        uses: olxbr/lighthouse-ci-action@v1
        with:
          urls: |
            http://localhost/
          runs: 3
          temporaryPublicStorage: true # upload lighthouse report to the temporary storage
          configPath: ./.lighthouserc.yml # 
```

## Recommendations

- Collect the metrics at least 3 times for each URL using the `runs: 3` option in order to have a better precision in the result, since it will be an average of the executions.
- Create a customized lhci configuration file according to the project and use the `configPath: ./.lighthouserc.yml` option to indicate its location for the action.
- Use the `temporaryPublicStorage: true` option which will generate a url with the detailed result of the metrics collection.
- If you want to know the difference between the metrics in relation to the current code, in the CI pipeline run the action with the current version, which can be a `tag` or the `main` branch and then with the modified version in the Pull Request.

## Inputs

#### `urls`

Provide the list of URLs separated by a new line.
Each URL is audited using the latest version of Lighthouse and Chrome preinstalled on the environment.

```yml
urls: |
  https://example.com/
  https://example.com/blog
  https://example.com/pricing
````

#### `uploadArtifacts` (default: false)

Upload Lighthouse results as [action artifacts](https://help.github.com/en/actions/configuring-and-managing-workflows/persisting-workflow-data-using-artifacts) to persist results. Equivalent to using [`actions/upload-artifact`](https://github.com/actions/upload-artifact) to save the artifacts with additional action steps.

```yml
uploadArtifacts: true
```

#### `temporaryPublicStorage` (default: false)

Upload reports to the [_temporary public storage_](https://github.com/GoogleChrome/lighthouse-ci/blob/master/docs/getting-started.md#collect-lighthouse-results).

> **Note**: As the name implies, this is temporary and public storage. If you're uncomfortable with the idea of your Lighthouse reports being stored
> on a public URL on Google Cloud, use a private [LHCI server](#serverBaseUrl). Reports are automatically deleted 7 days after upload.

```yml
temporaryPublicStorage: true
```

#### `budgetPath`

Use a performance budget to keep your page size in check. `Lighthouse CI Action` will fail the build if one of the URLs exceeds the budget.

Learn more about the [budget.json spec](https://github.com/GoogleChrome/budget.json) and [practical use of performance budgets](https://web.dev/use-lighthouse-for-performance-budgets).

```yml
budgetPath: ./budget.json
```

#### `runs` (default: 1)

Specify the number of runs to do on each URL.

> **Note**: Asserting against a single run can lead to flaky performance assertions.
> Use `1` only to ensure static audits like Lighthouse scores, page size, or performance budgets.

```yml
runs: 3
```

#### `configPath`

Set a path to a custom [lighthouserc file](https://github.com/GoogleChrome/lighthouse-ci/blob/master/docs/configuration.md) for full control of the Lighthouse environment and assertions.

Use `lighthouserc` to configure the collection of data (via Lighthouse config and Chrome Flags), and CI assertions (via LHCI assertions).

```yml
configPath: ./lighthouserc.json
```

If some configurations aren't set using action parameters, the settings are fetched from the config file provided here.

#### `serverBaseUrl`

Upload Lighthouse results to a private [LHCI server](https://github.com/GoogleChrome/lighthouse-ci) by specifying both `serverBaseUrl` and `serverToken`.
This will replace uploading to `temporary-public-storage`.

```yml
serverBaseUrl: ${{ secrets.LHCI_SERVER_BASE_URL }}
serverToken: ${{ secrets.LHCI_SERVER_TOKEN }}
```

> **Note**: Use [Github secrets](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets#creating-encrypted-secrets) to keep your token hidden!

#### `basicAuthUsername` `basicAuthPassword`

Lighthouse servers can be protected with basic authentication [LHCI server basic authentication](https://github.com/GoogleChrome/lighthouse-ci/blob/master/docs/server.md#basic-authentication) by specifying both `basicAuthUsername` and `basicAuthPassword` will authenticate the upload.

```yml
basicAuthUsername: ${{ secrets.LHCI_SERVER_BASIC_AUTH_USERNAME }}
basicAuthPassword: ${{ secrets.LHCI_SERVER_BASIC_AUTH_PASSWORD }}
```

> **Note**: Use [Github secrets](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets#creating-encrypted-secrets) to keep your username and password hidden!

## Outputs

Use outputs to compose results of the LHCI Action with other Github Actions, like webhooks, notifications, or custom assertions.

### `resultsPath`

A path to `.lighthouseci` results folder:

```
/Users/lighthouse-ci-action/.lighthouseci
```

### `links`

A JSON string with a links to uploaded results:

```js
{
  'http://localhost/': 'https://storage.googleapis.com/lighthouse-infrastructure.appspot.com/reports/1676382590922-16051.report.html'
  ...
}
```

### `assertionResults`

A JSON string with assertion results:

```js
[
  {
    name: 'maxNumericValue',
    expected: 61440,
    actual: 508455,
    values: [508455],
    operator: '<=',
    passed: false,
    auditProperty: 'total.size',
    auditId: 'resource-summary',
    level: 'error',
    url: 'http://localhost/',
    auditTitle: 'Keep request counts low and transfer sizes small',
    auditDocumentationLink: 'https://developers.google.com/web/tools/lighthouse/audits/budgets',
  },
  ...
]
```

### `manifest`

A JSON string with report results ([LHCI docs reference](https://github.com/GoogleChrome/lighthouse-ci/blob/master/docs/configuration.md#outputdir)):

```json
[
  {
    "url": "http://localhost/",
    "isRepresentativeRun": true,
    "htmlPath": "/Users/lighthouse-ci-action/.lighthouseci/localhost-_-2023_02_14_13_49_30.report.html",
    "jsonPath": "/Users/lighthouse-ci-action/.lighthouseci/localhost-_-2023_02_14_13_49_30.report.json",
    "summary": {"performance":1, "accessibility":0.71, "best-practices":0.92, "seo":0.6, "pwa":0}
  }
]
```
