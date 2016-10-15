classdef Exerciser
  
  properties (Hidden, Access = private)
    token = '';
    placeholder = '';
    xml_obj = '';
  endproperties
  
  properties (Hidden, Access = public)

  endproperties

  methods
  
    function obj = Exerciser(filePath)
    % Class constructor
    
      % Parse xml
      obj.xml_obj = xmlread(filePath);
      obj.token = obj.get_global_xml_field('token'){1};
      obj.placeholder = obj.get_global_xml_field('placeholder'){1};
    
    endfunction

    function process(obj)
    % Remove file parts, generate expected outputs
      
      % Iterate over exercises
      exercises = obj.xml_obj.getElementsByTagName('exercise');
      for ii = 0 : exercises.getLength - 1 % Java's 0-based indexing
        ex = exercises.item(ii);
        obj.proces_one(ex);
      endfor
      
    end
    
  endmethods
  
  methods (Hidden, Access = private)
  
    function proces_one(obj, ex)
    % Process one exercise
      
      files = obj.get_xml_field_from_node(ex, 'file');
      inpaths = obj.get_xml_field_from_node(ex, 'input');
      outdir = obj.get_xml_field_from_node(ex, 'outputdir'){1};
      
      obj.process_files(files, outdir);
      
      num_inputs = numel(inpaths);
      inputs = cell(1, num_inputs);
      
      for ii = 1 : num_inputs
        inputs{ii} = im2double(imread(inpaths{ii}));
      end
      
      % We expect only one entry-point function per exercise and one or multiple
      % inputs/outputs
      outputs = obj.generate_expected_outputs(files{1}, inputs);
      
      obj.generate_checker_spec(inputs, outputs, files{1}, outdir);
      
    endfunction
    
    function generate_checker_spec(obj, inputs, outputs, funcpath, outdir)
    % Generate specification that the checker script will use to verify results
    
      [~, fname, ~] = fileparts(funcpath);
      outname = sprintf('%s.result.mat', fname);
      full_outname = fullfile(outdir, outname);
      save('-binary', full_outname, 'inputs', 'outputs');
    
    endfunction
    
    function outs = generate_expected_outputs(obj, file, inputs)
    % Generate expected outputs given the function and its inputs
      
      [fpath, fname, ~] = fileparts(file);
      
      % Change dir to evaluate function
      curr_path = pwd();
      cd(fpath)
      num_outputs = nargout(fname);
      outs = cell(1, num_outputs);
      [outs{:}] = feval(fname, inputs{:});
      close('all')
      
      % Return to previous dir
      cd(curr_path)
    
    endfunction
    
    function process_files(obj, file_list, outdir)
    % Process added files to remove parts
      
      num_files = numel(file_list);

      for ii = 1 : num_files
        curr_file = file_list{ii};
        try
          curr_out_file_contents = obj.remove_parts(curr_file);
          obj.create_dir_if_needed(outdir);
          wfile = write_processed_file(obj, curr_file, curr_out_file_contents, outdir);
        catch
          % TODO: display caught error
          fprintf("Warning: File skipped: %s\n", curr_file) % TODO: writeln function
        end_try_catch
      endfor
    
    endfunction
    
    function out = get_global_xml_field(obj, field)
    % Get xml field from the xml_obj
    
      len = obj.xml_obj.getElementsByTagName(field).getLength();
      
      out = cell(1, len);
      for ii = 0 : len - 1 % Java's zero-based indexing
        out{ii + 1} = obj.xml_obj.getElementsByTagName(field).item(ii).getFirstChild.getTextContent;
      endfor
      
    endfunction
    
    function out = get_xml_field_from_node(obj, node, field)
    % Get xml field from the xml_obj
    
      len = node.getElementsByTagName(field).getLength();
      
      out = cell(1, len);
      for ii = 0 : len - 1 % Java's zero-based indexing
        out{ii + 1} = node.getElementsByTagName(field).item(ii).getTextContent; %getFirstChild.getTextContent;
      endfor
      
    endfunction
    
    function out = remove_parts(obj, filepath)
    % Remove tagged parts of a file

      % Get token
      token = obj.token;

      file_contents = fileread(filepath);

      pat = "\n%%";
      positions = strfind(file_contents, pat); % find section beginnings
      out = file_contents(1:positions(1)); % grab the first part of the file
      num_positions = length(positions);

      % Iterate over file parts
      for ii = 2 : num_positions + 1
        if ii <= num_positions % non-last part
          file_part = file_contents(positions(ii-1):positions(ii));
        else % last part
          assert(ii == num_positions + 1, 'Iterator value too large.')
          file_part = file_contents(positions(ii-1):end);
        endif  
        first_line = strread(file_part, '%s', 'delimiter', sprintf('\n')){2};
        is_hide = ~isempty(strfind(file_part, token));
        if is_hide
          out = strcat(out, remove_code(obj, file_part));
        else
          out = strcat(out, file_part);
        end
      end

    endfunction

    function comments = remove_code(obj, comments_and_code)

      token = obj.token;
      
      comments = "";

      all_lines = strread(comments_and_code, '%s', 'delimiter', sprintf('\n'));

      ii = 2; % first element is empty
      curr_line = strrep(all_lines{ii}, token, ""); % remove token from first line
      while strcmp(curr_line(1), "%")
        comments = strcat(comments, curr_line, sprintf('\n'));
        ii = ii + 1;
        curr_line = all_lines{ii};
      end

      comments = strcat(comments, sprintf('\n%s\n\n', obj.placeholder));

    endfunction
    
    function outfpath = write_processed_file(obj, orig_file_name, file_contents, outdir)
    % Write processed contents to an output file
    
      [path, name, ext] = fileparts(orig_file_name);
      new_file_name = fullfile(outdir, strcat(name, ext));
      fid = fopen(new_file_name, 'w');
      try
        fprintf(fid, "%s", file_contents);
      catch
        % Do nothing, just avoid stopping the program execusion before
        % closing the file
      end_try_catch  
      fclose(fid);
      outfpath = new_file_name;
    
    endfunction
    
    function create_dir_if_needed(obj, outdir)
    % Create output dir if it doesn't exist
    
      if ~exist(outdir, 'dir')
        mkdir(outdir);
      endif
    
    endfunction
  
  endmethods

endclassdef