# as-tspu mikrotik on premise script, 
# may be slow on low-end routers, use with caution
# 
# https://github.com/Viktor45/as-tspu

# comment to mark list lines at addresslist
:local targetComment ("TSPU")
# name of the addresslist to add entries
:local listName ("bypass")

# path to temp folder
:local tmpPath "usb1/tmp/"
# :local tmpPath "tmp/"

:local url ""

# choose appropriate url here
# ipv4 only
:set url ("https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/ipv4-agg.txt")
# ipv6 only
# :set url ("https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/ipv6-agg.txt")
# ipv4 and ipv6
# :set url ("https://raw.githubusercontent.com/Viktor45/as-tspu/refs/heads/main/ipverse/merged-agg.txt")

:local tempFile ($tmpPath . "as-tspu.txt")
# Fetch file
:do { /file remove $tempFile } on-error={}

:do {
    /tool fetch url=$url dst-path=$tempFile mode=https
    :delay 2s
    :log info ("as-tspu: reading file")
    # Read and process
    :local fsize [/file get $tempFile size]
    :local max 32768
    :local chunks (($fsize / $max) - 1)
    :if ($fsize > ($max * $chunks)) do={
        :set $chunks ($chunks + 1)
    }

    :local content
    :for i from=0 to=$chunks do={
        # Start each read from the next chunk
        :local offset ($i * $max)
        :local filechunk [/file/read file=$tempFile offset=$offset chunk-size=$max as-value]
        :set $content ($content . ($filechunk->"data"))
    }
    :log info ("as-tspu: file loaded")
    # Parse lines manually
    :local lines [:toarray ""]
    :local currentLine ""
    :local lineCount 0
    :local contentLen [:len $content]

    :log info ("as-tspu: parsing lines...")
    :for i from=0 to=($contentLen - 1) do={
        :local char [:pick $content $i ($i + 1)]

        :if ($char = "\n") do={
            :if ([:len $currentLine] > 0) do={
                :set ($lines->$lineCount) $currentLine
                :set lineCount ($lineCount + 1)
                :if ($lineCount % 333 = 0) do={
                    :log info ("as-tspu: lines parsed: $lineCount")
                }
            }
        :set currentLine ""
        } else={
            :if ($char != "\r") do={
                :set currentLine ($currentLine . $char)
        }
        }
    }

    # Add last line if exists
    :if ([:len $currentLine] > 0) do={
        :set ($lines->$lineCount) $currentLine
        :set lineCount ($lineCount + 1)
    }

    :local total $lineCount
    :log info ("as-tspu: lines found: $lineCount")
    # Remove old entries
    :do {
        /ip firewall address-list remove [/ip firewall address-list find list=$listName comment=$targetComment]
    } on-error={}
    :do {
        /ipv6 firewall address-list remove [/ipv6 firewall address-list find list=$listName comment=$targetComment]
    } on-error={}

    # Process each line
    :local added 0
    :local skipped 0

    :for i from=0 to=($total - 1) do={
        :local line ($lines->$i)
        :local lineLen [:len $line]

        # Skip empty lines
        :if ($lineLen = 0) do={
            :set skipped ($skipped + 1)
        } else={
            # Skip comment lines
            :local firstChar [:pick $line 0 1]
            :if ($firstChar = "#") do={
                :set skipped ($skipped + 1)
            } else={
                :do {
                    :if ([:typeof $line] = "ip6" || [:typeof $line] = "ip6-prefix") do={
                    /ipv6 firewall address-list add address=$line list=$listName comment=$targetComment
                } else={
                    /ip firewall address-list add address=$line list=$listName comment=$targetComment
                }
                :set added ($added + 1)
                } on-error={}
            }
        }
    }

    :log info ("as-tspu: Added $added prefixes")

    # Cleanup
    /file remove $tempFile

} on-error={
    :log error ("as-tspu: Failed to process list")
    :do { /file remove $tempFile } on-error={}
}