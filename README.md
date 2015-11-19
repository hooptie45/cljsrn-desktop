# ClojureScript React Native Desktop

A proof-of-concept demo using [react-native-desktop](https://github.com/ptmt/react-native-desktop) from ClojureScript.

# Blog Post / Demo

[Blog Post with Demo](http://blog.fikesfarm.com/posts/2015-11-19-clojurescript-react-native-desktop.html)

# Running

Note, this stuff was copied from iOS without much change. As a consequence it currently puts some files in `~/Library/Private Documents/cljs-out/`

### ClojureScript
1. `cd ui-explorer`
2. `lein cljsbuild once dev`
3. After steps below are complete and app is running, `./repl`

### Native

1. `cd rnd`
2. `npm install`
3. `cd Examples/UIExplorer`
4. `pod install`
5. `open UIExplorer.xcworkspace`
6. Run the app in Xcode