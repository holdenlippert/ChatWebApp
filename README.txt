# Chat Web App

This is a web frontend to the chat app built as part of the class I took and TA'd in college.

The intention is for this to serve as a demonstration of one of the key concepts in that class, that strong decoupling between elements of the architecture allow for significant changes to be made to individual elements without affecting others. In this case, I'm swapping out a simple Java Swing window for an entire server/client web architecture with a webpage written in Elm, which I'd say is a rather significant change.

It also hopefully serves as a good demonstration of the way that peer-to-peer and server/client architectures can coexist in the same system.

I've wanted to do this for several years and when I wanted a project with which I could learn Elm, it seemed like a good time to finally do it.

It is currently rather bare bones and doesn't actually interface with anything but a dummy server written with Express.js.

A note to any students from that class who happen to stumble upon this project: there is no code or design here that will help you with your own project. If you attempt to use anything you find here, it will most likely only cause more problems for you. Tell Wong I said hi.
## Set Up

Run the following command in the root directory to compile:

```bash
elm make src/Main.elm --output elm_app.js
```

To install the needed Node.js packages, run
```
npm install
```
in the Server directory.

## Usage

Open the `index.html` file to view the webpage. Run `node Server/index.js` to initiate the backend.
