object @amplification_option
attribute :cq_method, :min_fluorescence, :min_reliable_cycle, :min_d1, :min_d2, :baseline_cycle_bounds
 
node(:errors, :unless => lambda { |obj| obj.errors.empty? }) do |o|
  o.errors
end