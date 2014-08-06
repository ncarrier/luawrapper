local M = {}

local bar = require "doe"

function M.foo()
    bar.baz("Hello World!")
end

return M