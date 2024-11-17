
# Utility functions
"""
    format_iso8601(dt::DateTime)

Format a DateTime to ISO 8601 format with exactly three millisecond digits.
"""
function format_iso8601(dt::DateTime)
    year = Dates.year(dt)
    month = lpad(Dates.month(dt), 2, '0')
    day = lpad(Dates.day(dt), 2, '0')
    hour = lpad(Dates.hour(dt), 2, '0')
    minute = lpad(Dates.minute(dt), 2, '0')
    second = lpad(Dates.second(dt), 2, '0')
    ms = lpad(round(Int, Dates.value(Dates.Millisecond(dt)) % 1000), 3, '0')
    return "$(year)-$(month)-$(day)T$(hour):$(minute):$(second).$(ms)Z"
end

"""
    get_system_metadata()

Generate system metadata for Weave API calls.
"""
function get_system_metadata()
    Dict(
        "weave" => Dict(
        "client_version" => string(pkgversion(WeaveLoggers)),
        "source" => "julia-client",
        "os" => string(Sys.KERNEL),
        "arch" => string(Sys.ARCH),
        "julia_version" => string(VERSION)
    )
    )
end