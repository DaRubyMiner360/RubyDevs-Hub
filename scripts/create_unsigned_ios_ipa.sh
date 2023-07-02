flutter build ios
mkdir -p build/ios/ipa/Payload/
cp -r build/ios/iphoneos/Runner.app/ build/ios/ipa/Payload/Runner.app/
cd build/ios/ipa/
zip -r "RubyDevs Hub.ipa" Payload
cd ../../../
echo "Built unsigned IPA to 'build/ios/ipa/RubyDevs Hub.ipa'"
