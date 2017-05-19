ems = ExtManagementSystem.find_by(:name => ENV['EMS'])

vms = ems.vms

vm_count = vms.count
expected = 1234

raise "Expected #{expected} VMs but got #{vm_count}" if vm_count != expected

vms.each do |vm|
  raise "Invalid availability zone for VM #{vm.ems_ref}" if vm.availability_zone.nil?
  raise "Invalid flavor for VM #{vm.ems_ref}"            if vm.flavor.nil?
  raise "Invalid location for VM #{vm.ems_ref}"          if vm.location.nil?
  raise "Invalid stack for VM #{vm.ems_ref}"             if vm.orchestration_stack.nil?
  raise "Invalid hardware for VM #{vm.ems_ref}"          if vm.hardware.nil?
end

template_count = ems.miq_templates.count
raise "Expected #{expected} Templates but got #{template_count}" if template_count != expected

hardware_count = ems.hardwares.count
raise "Expected #{expected} Hardwares but got #{hardware_count}" if hardware_count != expected

az_count = ems.availability_zones.count
raise "Expected #{expected} Availability Zones but got #{az_count}" if az_count != expected

flavor_count = ems.flavors.count
raise "Expected #{expected} Flavors but got #{flavor_count}" if flavor_count != expected

stack_count = ems.orchestration_stacks.count
raise "Expected #{expected} Stacks but got #{stack_count}" if stack_count != expected

key_count = ems.key_pairs.count
raise "Expected #{expected} Keys but got #{key_count}" if key_count != expected

puts "Success!"