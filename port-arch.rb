require "code-assertions"

NAME = `echo $USER`
CONFIG_BLACKLIST = %w(/etc/passwd /etc/ssl /etc/ssh /etc/resolv.conf)

unless FileTest.exist? "packages.txt"
    warn "Extracting the list of packages..."
    `pacman -Qent > packages.txt`
else
    warn "Skipping packages extraction"
end

# assert { FileTest.exist?("packages.txt") }

unless FileTest.exist?("to-install") || FileTest.exist?("programs.tar.gz")
    warn "Copying meaningful packages..."
    `mkdir -p "to-install"`
    File.read("packages.txt").split("\n").each do |package|
        package.sub! " ", "-"
        
        matching = Dir.glob("/var/cache/pacman/pkg/#{package}*")
        
        assert(package) { matching.size == 1 }
        matching = matching[0]
        basename = File.basename(matching)
        `cp "#{matching}" "to-install/#{basename}"`
    end
else
    warn "Skipping packages copy..."
end

unless FileTest.exist? "programs.tar.gz"
    warn "Compressing programs..."
    `tar -zcvf programs.tar.gz to-install`
else
    warn "Skipping program compression..."
end

unless FileTest.exist?("etc") || FileTest.exist?("data.tar.gz")
    warn "Copying configuration files..."
    Dir.glob("/etc/**/*").select { |filename| FileTest.file?(filename) }.each do |filename|
        base = filename.sub("/etc/", "")
        dir = File.dirname(base)
        `mkdir -p "etc/#{dir}"`
        
        begin
            content = File.read(filename)
            
            if content.include? NAME
                warn "\tSkipping #{filename} because it contains the username..."
            elsif CONFIG_BLACKLIST.any? { |blacklisted| filename.start_with?(blacklisted) }
                warn "\tSkipping #{filename} because it is in the blacklist..."
            else
                `cp "#{filename}" "etc/#{base}"`
            end
        rescue Errno::EACCES
            warn "\tSkipping #{filename} (no read access)"
        end
    end
else
    warn "Skipping configuration copy..."
end

unless FileTest.exist? "data.tar.gz"
    warn "Compressing configuration files..."
    `tar -zcvf data.tar.gz etc`
else
    warn "Skipping configuration compression..."
end

warn "Cleaning up..."

`rm packages.txt`
`rm -r to-install`
`sudo rm -r etc`

warn "Everything is ready!"
