local LOGGING_ENABLED = true;

function log(value)
    if (not LOGGING_ENABLED) then
        return
    end

    spdlog.info(value)
end