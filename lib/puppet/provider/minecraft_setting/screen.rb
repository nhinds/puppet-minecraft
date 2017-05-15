require 'json'

Puppet::Type.type(:minecraft_setting).provide(:screen) do
  def value
    JSON.load(File.new(resource[:filename])).map { |o| o[resource[:id_property]] }
  end

  def value=(newvalue)
    current = value
    (current - newvalue).each do |to_remove|
      Puppet.debug "Need to remove #{to_remove}"
      screencmd sprintf(resource[:remove_command], to_remove)
    end
    (newvalue - current).each do |to_add|
      Puppet.debug "Need to add #{to_add}"
      screencmd sprintf(resource[:add_command], to_add)
    end
  end

  private
  def screencmd(cmd)
    execute(['screen', '-p', '0', '-S', resource[:instance], '-X', 'eval', %Q(stuff "#{cmd}"\\015)],
	    failonfail: true, uid: resource[:user])
  end
end
