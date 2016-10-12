% IO package and Xerces library required for XML parsing
% NOTE: Standard Octave distributions do not include Xerces library. You will
% need to install it manually and adjust the below paths to point to the .jar
% files.
pkg load io
javaaddpath("C:/Program Files/xerces-2_11_0/xercesImpl.jar")
javaaddpath("C:/Program Files/xerces-2_11_0/xml-apis.jar")

% Image package required for reading images
pkg load image

% Add path to Exerciser class
addpath('../')

% Instantiate an exerciser object
ex = Exerciser('default.xml');

% Process files
ex.process()
