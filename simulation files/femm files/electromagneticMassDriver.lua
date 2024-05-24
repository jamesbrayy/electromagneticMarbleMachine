-- femm4.2 Simulation of RLC circuit for slug acceleration.
-- January 2016
-- written by uses_tools for the instructable "Coil Gun Simulation with femm4.2"

showconsole()

femfile = "coilGunDemo.fem" 

Results_file =          "run6_res.csv"
Results_overview_file = "run6_ovvw.csv"

-- mydir="c:\\femm42\\Coilgun\\"      -- or 
mydir="./"

-- write all constants to file
 open(mydir .. femfile )
 mi_saveas(mydir .. "temp.fem")	-- copy file to temporary in order not to alter the original

end_time = 0.01 -- end point at 20 ms

m = 0.017 -- mass of slug; This relates to a steel slug, 9.6mm dia, 50mm length, rounded tip. It weighs 25g.

V0 = 200 -- [Volt]; start voltage in Cap

Cap = 0.024 -- capacitor in F

R_cap = 0.038 -- 38 mOhm for 6800 uF Cap
-- see suggestions for different capacitor sizes/types

R_wiring = 0.010 -- a Guess: 10 MilliOhm for all interconnections and AWG12 or thicker connecting wire. 
               -- AWG12 wiring has about 1mOhm per 8 inches. 
               -- An interconnect has about 1mOhm.

R_switch = 0.0035 -- resistive part of SCR losses 3.5mOhm
V_switch = 0.9   -- the current independent voltage drop in the switching SCR

freewheeling_diode = 0
R_diode = 0.000
-- freewheeling_diode = 1
-- R_diode = 0.300


-- h = 1e-4 -- timestep [s]
h = 0.5e-4 -- timestep [s]

-- start position of slug:
z0 = 0.000 -- mm into coil; negative numbers mean the slug tip is outside of the coil
print("z0 chosen:",z0)

v = 0 -- [m/s] start speed of slug

total_length = 50 -- mm; length of coil

layers = 4 -- number of wire layers
-- Wire thickness; resistance and diameter come from the lookup table
awg = 12

-- radius of bobbin for the coil
r_start = 8.20 -- mm

Number = 6 -- Number of simulation


-- table of wire sizes by AWG:
--                   1       5         10      12              15    16     17    18      19     20     21    22      23    24
length_resistance = {1,1,1,1,1,1,1,1,1,1,  1,5.31,6.7 ,8.43,10.66, 13.45, 16.95, 21.37, 26.99, 33.86, 42.78, 54.43, 67.81, 85.93} -- milliohm/meter
dia_copper =        {1,1,1,1,1,1,1,1,1,1,  1,2.05,1.83,1.62, 1.45,  1.29,  1.15,  1.02,  0.91,  0.81,  0.72,  0.64,  0.57, 0.51} -- mm copper
diameter =          {1,1,1,1,1,1,1,1,1,1,  1,2.13,1.90,1.71, 1.52,  1.37,  1.25,  1.09,  0.98,  0.88,  0.78,  0.71,  0.63, 0.57} -- mm copper + varnish


-- set size of coil
      mi_zoom(-10,-50,40,80)  -- zoom in
      mi_refreshview()
      mi_saveas(mydir .. "temp.fem")

-- calculate wire length:
      d_m = 2 * r_start + (diameter[awg] * layers) -- mm; median diameter in coil

    wire_length = 0.97 * total_length / diameter[awg] * 0.001 * layers * d_m / diameter[awg] * 3.14159 -- meter; 
    -- turns per total length * layers * PI()* median diameter

    print("R of coil[mOhm]:", wire_length * length_resistance[awg] )

    R = wire_length * 0.001 * length_resistance[awg] + R_wiring + R_switch + R_cap

    turns = 0.97 * layers * total_length / diameter[awg] -- 0.97 because of imperfections in the turns; 
    -- also no hexagonal packing, wires take up a square cross section

    r_a = r_start + layers * diameter[awg]

-- pause()

    print("ri:",r_start,"ra:",r_a,"layers:",layers,"turns:",turns,"wire_length:",wire_length,"[m] R of circuit:",R,"\n")
    print("d_m[mm]:",d_m,"circ_m[mm]:",3.14159 * d_m,"wire dia[mm]",diameter[awg],"length_res of wire[mOhm/m]",length_resistance[awg],"\n")
    print("total turns:",turns)

-- set number of turns for electrical
      mi_selectgroup(2) -- coil
      mi_setblockprop("12 AWG",0,0.3,"Coil",0,2,turns)
      mi_refreshview()


-- dry run without movement to determine initial inductance 
-- fe: calculate F and L, position = z

   i_trial = 500

  mi_selectgroup(2)
  mi_addcircprop("Coil", i_trial  , 1) -- just use 500A
  mi_analyze()
  mi_loadsolution()
  mo_groupselectblock(2) -- coil
  AJ=mo_blockintegral(0) -- Energy in coil
  L_0 = 2*AJ/(i_trial * i_trial ) 
                   -- beware: the original formula is stated wrong in the femm example! 
                   -- Stored energy AJ = 1/2 * L * i^2 according to physics textbooks
                   -- this is the initial inductance with the slug in start position 

 print("initial L[milliHy]:", L_0 * 1000)


 print("Start Pos. z0[mm]:",z0,"v[m/s]:",v,"mass=",m,"Cap[uF]:",1E6 * Cap,"Start Voltage[V]:",V0,"Inductance:",L,"timestep:",h,"Res:",R)

-- write initial parameters

 handle = openfile(mydir .. Results_file ,"a") -- append mode
 write(handle,"Number,",Number,",AWG:,",awg,",Layers:,",layers,",Length,",total_length,",Mass[g]:,",m*1000,",Cap[uF]:,",Cap*1000000,",V0 [V]:,",V0,",L[uHy]:,",(L_0 * 1E6),",Start pos[mm]:,",z0,",v_0[m/s]:,",v,",t-incr[ms]:,",(h*1000),",..,",(end_time*1000),",ms R[Ohm]:,",R,",\n")
-- top of csv file
 write(handle, "file = ",femfile,"\n")
 write(handle, "Diode used:,",freewheeling_diode,",R_diode,",R_diode,",\n")
 write(handle, "t , i , dz , F , L , dL , V_Cap ,  v , a\n")
 closefile(handle)

-- reset variables:
i = 0
i_old = 0 -- current
sum_i = 0

L_old = L_0
V_Cap_old = V0
V_Cap     = V0

z=z0 ; z_old = z0
t=0;
v_old = v
vmax = 0
i_max = 0
L_max = 0
i_rev_flag = 0
recordcounter = 1

-- start of timestep loop ----------------------------------------

for t = 0,end_time,h do

--  if z < 0.160 then -- stop when slug exited coil
  if ( z < (total_length + 50) * 1e-3) then
    print("z[m]:",z)
    print("freewheeling diode used:",freewheeling_diode)

  -- fe: calculate F and L, position = z

  mi_analyze()
  mi_loadsolution()
  mo_groupselectblock(1) -- slug
  F=mo_blockintegral(19) -- force in Z direction

   -- A.J; L = 2*A.J / i^2 
  mo_groupselectblock(2) -- coil
  AJ=mo_blockintegral(0) -- Energy in coil

   if (i~=0) then
      L = 2*AJ/(i*i)         -- new inductance
   else
      L = L_0
  end

  print("new L[uH]:",1E6 *L)

  mo_zoom(-10,-50,40,80) -- zoom in

  if t == 0 then 
            mo_refreshview()
  end

  sum_i = sum_i + i_old -- add all discharges (via curent * h) for capacitor discharge calc

  if (i_rev_flag ~= 1) then
	if ( (V_Cap > -1.0) and (freewheeling_diode == 1) ) or (freewheeling_diode == 0) then

            R = wire_length * 0.001 * length_resistance[awg] + R_wiring + R_switch + R_cap
            i = (i_old * (L/h) + V0 - V_switch - (h/Cap) * sum_i) /  (R + L/h + h/Cap)
            V_Cap = (V0 - V_switch) - (h/Cap) * sum_i 

        else

            if ( (V_Cap <= -1.0) and (freewheeling_diode == 1) ) then
               R = wire_length * 0.001 * length_resistance[awg] + R_wiring + R_switch + R_diode
               i = (i_old * (L/h) + V_Cap) /  (R + L/h)
       	    end

            V_Cap = V_Cap_old

        end
  else
    i = 0 
  end


  print ("current:", i,"[A]")

  print("z-pos.",z,"[mm]")

  if ( i_old > 0 and i <= 0 ) then
	i_rev_flag = 1
	i = 0 -- SCR switched off
	print ("Current set to 0\n")
 end


  mi_addcircprop("Coil", i, 1)

--  if V_Cap > -1.0 then
--       V_Cap = (V0 - V_switch) - (h/Cap) * sum_i 
             -- or V_Cap = V_Cap_old - (h/Cap)*i
--  else
--       V_Cap = V_Cap_old
--  end

a = F/m
v = v_old + a*h
z_adv = (v*h + a*0.5*h*h) -- advancement z during time interval h [m]
print("z advance [mm]:",z_adv * 1000.0 )
z = z_old + z_adv -- position [m]
print("new z [mm]:",z * 1000.0)

if v > vmax then
 vmax = v
end

-- detect maximum inductance
if t > (2 * h) and L > L_max then
   L_max = L
end

if i > i_max then
  i_max = i
end

if t > (2 * h) then
  dL = (L - L_old)/(z - z_old) * 1E3-- mH change in inductance
else
 dL = 0
end

-- write all results to file
-- write(handle, "t ,i ,z ,F ,L ,dL/dx ,V_Cap ,v , a\n")

-- only every 5th result is stored to reduce the amount of data
if (recordcounter == 1) then
 handle = openfile(mydir .. Results_file ,"a") -- append mode
 write(handle,  t*1E3,",",i,",",z*1000,",",F,",",L*1E6,",",dL,",",V_Cap,",",v,",",a,"\n")
 closefile(handle)
end

 recordcounter = recordcounter + 1
 if recordcounter > 5 then 
   recordcounter = 1 
 end

print("Rec_ctr:",recordcounter,"\n")


 print("time[ms]:",1000*t,"Pos[mm]:",1000 * z," v[m/s]=",v," Current[A]:",i,"V_Cap[V]:",V_Cap )
 print("Force[N]:",F,"L[uHy]:",L*1E6," ",layers,"layers vmax[m/s]=",vmax,"AWG:",awg)

-- move one step forwards
i_old = i
z_old = z
v_old = v
V_old = V
L_old = L
V_Cap_old = V_Cap

     -- advance slug by x

     if  t<end_time then
         print("Advancing slug", z_adv * 1000.0)
         mi_selectgroup(1) -- slug
	 adv = z_adv * 1000.0 --[mm]
         mi_movetranslate(0,adv) -- mm up
     end

     -- automatic: t = t+h

print ("v[m/s]:",v,"vmax:",vmax,"\n")

 end -- if z < 0.120 [m]
 end -- for -- timesteps

-- end of timestep loop ------------------------------------------

print("End of timesteps")


 mo_close() -- make sure the open files do not accumulate
 mi_close()

 handle = openfile(mydir .. Results_file,"a") -- append mode
 write(handle,  "vmax[m/s]:,",vmax,", vend[m/s]:,",v,",start pos[mm]:,",z0*1000,",imax[A]:,",i_max,",\n")
 closefile(handle)

 handle = openfile(mydir .. Results_overview_file,"a") -- append mode
 write(handle, "Num,",Number,",vmax:,",vmax,",[m/s] vend:,",v,",Start pos[mm]:,",z0,",imax:,",i_max,",AWG:,",awg,",Layers:,",layers,",Length,",total_length,",Mass[g]:,",m*1000,",Cap[uF]:,",Cap*1000000,",V0 [V]:,",V0,",L[uHy]:,",(L*1000000),",t-incr[ms]:,",(h*1000),",..,",(end_time*1000),",ms R[Ohm]:,",R,",\n")
 closefile(handle)

 print("Num",Number,"vmax[m/s]:",vmax,"vend[m/s]:",v,"Start pos[mm]:",z0 )
 print("imax[A]:",i_max,"AWG:",awg,"Layers:",layers,"Length[mm]:",total_length )
 print("Mass[g]:",m*1000,"Cap[uF]:",Cap*1000000,"V0[V]:",V0,"L[uHy]:",(L*1000000) )
 print("t-incr[ms]:",(h*1000),"....",(end_time*1000),"[ms] R_total[mOhm]:",R*1000 )

-- end of program
