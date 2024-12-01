# properinter.net website

This repo creates a snapshot of the <a href="https://sneaky-cry-8e7.notion.site/Proper-Internet-1463b3f59a6a8049966dd1e89fc5f3c4" target="_blank">Proper Internet</a> Notion public website and publishes it to CloudFlare Pages.

## Dependencies
```
brew install gh
```

## Deploy
Use the `deploy` GitHub Action from the command line to create a snapshot of the Notion public website. The workflow will create a pull request to `main` with the snapshot changes, auto merge it, deploy the repo to CloudFlare and purge the cache.
```
git clone git@github.com:proper-internet/website.git
cd website
gh workflow run deploy
```

## Preview
If you would like to preview the changes made in Notion, use the `snapshot` GitHub Action. The workflow will create a pull request to `main` with the snapshot changes. You can click `Preview URL` to take a look at the website before deploying. Merge the pull request to deploy the website to CloudFlare and purge the cache.

```
gh workflow run snapshot
```
