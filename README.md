# Rails Interview Project

Option 1 (Cloud 9):

1. You will be invited to a cloud9 account, create a new workspace -> clone workspace -> rails-lab
2. Everything should be already set up and good to go, and you have full access

Option 2 (clone to your own computer):

1. install brew if they don't have it (http://brew.sh/)
2. `brew install rbenv`
3. `rbenv install`
4. `gem install bundler`
5. `git clone git@github.com:clutter/clutter-interview-rails-current-events.git`
6. `cd clutter-interview-rails-current-events`

That should get you up and running, to run your local server run `rails s` in your terminal, with default settings that will let you access your app at `localhost:3000`

## Objective
Build an application that (pseudo) summarizes events on a given day scraped from Wikipedia. Each event should be persisted locally, such that subsequent requests for the same date will not trigger a visit to Wikipedia.

### Parsing Details
 * Given a date in the past (>= 1/1/2000), the app will parse each outer bullet point as an event.  For example, on [Jan 1, 2010](https://en.wikipedia.org/wiki/Portal:Current_events/January_2010#2010_January_1), there would be 10 events. Each event would be based on the first link encountered within the bullet point that leads to a wikipedia entry. Each event is highlighted with a red underline:

 ![wikipedia example image](https://s3.amazonaws.com/clutter-interview-assets/Portal_Current_events_January_2010_-_Wikipedia.png)

 * An event summary consists of the following fields:
   * title - same title as article
   * summary - The paragraphs above the Table of Contents in the article
   * image_url - A link to the first image encountered in the article

## Tasks
### Backend service
Create RESTful API endpoints to:
  * return all events for a given date
  * return all dates that have been cached locally

### UI
The UI consists of a couple views that consumes the services above:
* Events Summary Page - Allows user to view all events for a given date >= 1/1/2000
* Dates Index Page - View an index page that lists all locally cached dates, which are linkable to the associated Event Summary Page

## Notes
The application needs to be built with high-volume in mind:
* Assume that a lot of users will be viewing event summaries concurrently
* The persistence layer may eventually contain millions of results. Searching through the results still needs to be effective.
* Please do not use the Wikipedia API. Write a service to parse the DOM.

## Implementation requirements
* Use Postgres as a database
* Use a Bootstrap based UI
* Use JSON as the data protocol for the API service
* The UI should access the service using AJAX and not using server-side calls.
* Please supply specs for the services
