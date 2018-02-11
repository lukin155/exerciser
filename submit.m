function [in, expected, actual] = submit(function_name, epsilon)
% Perform a test to see if the given function generates the right outputs for
% the given input. Inputs and outputs are predefined in a .mat file that is
% located in the same folder and has the same name (except the extension) as the
% function being checked.
%
% NOTE: This function expects a path to a file - relative or absolute.
% NOTE: The optional argument epsilon (zero by default) defines the allowed
% tolerance for the difference between the generated result and the expected
% result.

% One optional out of two arguments
narginchk(1,2);

% The default value for the optional argument
if nargin < 2
  epsilon = 0;
endif

[fpath, fname, fext] = fileparts(function_name);
assert(isempty(fext) || fext == '.m', 'The supplied file should have a .m extension or no extension.)')

% Go to the dir where the funciton is
old_dir = pwd(); % save the path, so we can return to it in the end
cd(fpath)

% Files validation
results_file = sprintf('%s.result.mat', fname);
assert(2 == exist(fname), 'Cannot find the supplied file.')
assert(2 == exist(results_file),
  'A matching .result.mat file was expected in the same folder where the function file is located.')

% Read the info from the result spec
res = load(results_file);

% Read function inputs
inputs = res.inputs;

% Read expected function outputs
exp_outputs = res.outputs;

% Generate function outputs for comparison
num_outputs = numel(exp_outputs);
candidate_outputs = cell(1, num_outputs);
[candidate_outputs{:}] = feval(fname, inputs{:});

assert(num_outputs == numel(candidate_outputs),
  sprintf('Function returned %d outputs, expected %d.', num_outputs, numel(candidate_outputs)))

is_correct_num_outputs = 3 == nargout;

% Compare the outputs
for ii = 1 : num_outputs
  missmatches = abs(candidate_outputs{ii} - exp_outputs{ii}) > epsilon;
  s = sum(missmatches(:));
  if (0 == s)
    fprintf('Success!\n');
  else
    fprintf('Failed! The submitted function did not generate a correct result.\n');
    if ~is_correct_num_outputs
      fprintf('Call the script like this to get the epected and actual outputs:\n');
      fprintf('[input, expected, actual] = submit(file_name);\n');
    endif
  endif
endfor

if is_correct_num_outputs
  expected = exp_outputs;
  actual = candidate_outputs;
  in = inputs;
endif


% Return to original dir
cd(old_dir)

endfunction
