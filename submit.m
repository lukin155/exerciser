function [in, expected, actual] = submit(function_name)
% Perform a test to see if the given function generates the right outputs for
% the given input. Inputs and outputs are predefined in a .mat file that is
% located in the same folder and has the same name (except the extension) as the
% funtion being checked.
%
% NOTE: This function expects a path to a file - relative or absolute.

assert(nargin == 1, "Wrong number of input arguments.")

[fpath, fname, fext] = fileparts(function_name);
assert(isempty(fext) || fext == '.m', 'No extension or .m extension was expected.)')

% Go to the dir where the funciton is
old_dir = pwd(); % remember for later
cd(fpath)

% Files validation
results_file = sprintf('%s.result.mat', fname);
assert(2 == exist(fname), 'Cannot find the supplied function.')
assert(2 == exist(results_file),
  'a matching .result.mat file expected in the same folder where function is located.')

% Read the info from result spec
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

correct_num_outputs = 3 == nargout;

for ii = 1 : num_outputs
  missmatches = candidate_outputs{ii} ~= exp_outputs{ii};
  s = sum(missmatches(:));
  if (0 == s)
    fprintf('Success!\n');
  else
    fprintf('Outputs mismatch.\n');
    if ~correct_num_outputs
      fprintf('Call the script like this to get the epected and actual outputs:\n');
      fprintf('[input, expected, actual] = submit(file_name);\n');
    endif
  endif
endfor

if correct_num_outputs
  expected = exp_outputs;
  actual = candidate_outputs;
  in = inputs;
endif


% Return to original dir
cd(old_dir)

endfunction
