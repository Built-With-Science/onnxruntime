Patches applied to `js/react_native` of an upstream onnxruntime checkout before publishing.
`0001-install-jsi-on-react-native-0.88.patch` makes `ios/OnnxruntimeModule.mm` read the runtime pointer from the
bridge or the bridgeless bridge proxy and install the JSI bindings on it, so it compiles and works on React Native
0.88. It is written against upstream tag `v1.25.0`.
`scripts/bws-apply-patches.sh` applies every patch here, in order, in the publish-js-packages workflow.
