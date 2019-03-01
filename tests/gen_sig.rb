
include Math

noisy_sin = ->(f,t){sin(2*PI*f*t)+rand(-1..1).to_f/rand(3..10)}

FREQ=1
NB_SAMPLES=100
TEMPORAL_QUANTUM=(1/FREQ.to_f)/NB_SAMPLES

File.open("noisy_sin.dat",'w') do |f|
  for s in 1..NB_SAMPLES
    t=s*TEMPORAL_QUANTUM
    f.puts "%f %f" % [t,noisy_sin.call(FREQ,t)]
  end
end
