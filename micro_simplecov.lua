-- Runs everytime a file is saved
function onSave(view)
  -- Start an asynchronous process to attempt to identify the current file's
  --   project directory
  findProjectDirectory(view)

  -- false => Don't need to move the cursor
  return false
end

-- Given the project directory, returns the location of a coverage file,
--   assuming one exists.
function coverageFilePath(projectDirectory)
  -- Trim trailing new line from the project directory string
  projectDirectory = projectDirectory:sub(0, projectDirectory:len() - 1)
  return projectDirectory .. "/coverage/.resultset.json"
end

-- Assumes we are in git repo so we can find the project directory, which will
--   lead to the coverage file
-- Runs `git rev-parse --show-toplevel` to find the project directory
-- Invokes onProjectDirectoryFound callback when command exits
function findProjectDirectory(view)
  JobSpawn(
    'git',
    {'rev-parse', '--show-toplevel'},
    '', -- stdout callback
    '', -- stderr callback
    'micro_simplecov.onGitProjectDirectoryFound', -- exit callback
    view.Buf.AbsPath
  )
end

-- Callback run once we run the git command to find the project directory
-- takes the command output, and the absolute path to the file be marked
function onGitProjectDirectoryFound(output, filePath)
  -- This is what happens when it breaks
  local errorString = "fatal: Not a git repository"

  -- Make sure the command worked
  if string.find(output, errorString) == nil then
    local coverageFilePath = coverageFilePath(output)
    local coverageFile = io.open(coverageFilePath, 'rb')
    if coverageFile ~= nil then
      markCoverage(coverageFile)
    end
  else
    -- Add error to the log file if we weren't able to determine project dir
    messenger:AddLog("micro_simplecov: " .. output)
  end
end

function markCoverage(coverageFile)
  local coverageData = coverageFile:read("*a")
  -- Parsing json here is a PITA, so we will do it manually instead.
  -- Remove whitespace
  coverageData = string.gsub(coverageData, '%s', '')
  -- Find the start - index of "full/path/to/file.rb":[
  i, startIndex = string.find(coverageData, "\"" .. filePath .. "\":" .. '%[')
  if startIndex then
    -- Find the closing bracket of that array
    endIndex = string.find(coverageData, '%]', startIndex)

    -- Get only the coverage for the file we care about
    coverageData = string.sub(coverageData, startIndex + 1, endIndex - 1)

    -- Split by comma and iterate over that list
    local line_number = 0
    for line in string.gmatch(coverageData, "([^,]+)") do
      -- iterate line number (starts with 1)
      line_number = line_number + 1
      -- If the line has no coverage, mark it.
      -- The number here is number of times the code line has been executed by
      --   the last run of the test suite, so:
      --     null => The line doesn't need coverage (whitespace, etc)
      --     0    => The line has no coverage
      --     1+   => The line has coverage
      if line == "0" then
        -- Sets the gutter message (???, line number, message, severity (0-2))
        CurView():GutterMessage(
          "micro_simplecov",
          line_number,
          "No Test Coverage",
          2
        )
      end
    end
  end
end
