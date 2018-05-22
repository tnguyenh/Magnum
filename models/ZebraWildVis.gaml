
model ZebraWildVis

/* Insert your model definition here  updated in  Lyon 2018 Victor Mose*/

global {
	file shape_file_grass <- file("../includes/gis/gridsngreen.shp");
	file shape_file_zebra <- file("../includes/gis/zebragama.shp");
	file shape_file_wildebeest <- file("../includes/gis/wildebstgama.shp");
	file shape_file_agriculture <- file("../includes/gis/agriculture2010all.shp");
	file shape_file_park <- file("../includes/gis/national_park.shp");
	//file shape_file_habitats<-file("../includes/gis/ecosystem_vegetation_habitats.shp");
	file zebraIcon <-file("../images/zebra.jpg");
	file gnuIcon <-file("../images/gnu.jpg");
	
	geometry shape <- envelope(shape_file_grass);
	float step <- 10.0 #mn;
	float neighbours_range <- 20000.0;
	float meangreeness<-1.0;
	float meanbiomass<-1.0;
	float totalzebra;
	float totalwildebeest;
	float maxZebraDensity <- 1.0;
	float maxWildebeestDensity <- 1.0;


 
init {

		create grass from: shape_file_grass with: [pcgreen::float(read ("PCGREEN"))] {

			biomass<-pcgreen*carryingcapacity;
			color <- rgb(255 - int(255 * biomass/carryingcapacity),255,255 - int(255 * biomass/carryingcapacity));
		}
		create agriculture from: shape_file_agriculture with: [agric::string(read ("AGRICULTUR"))] {
			if agric="mygrass" {
				color <- #brown;
			}	
		}
		ask grass {
			do define_neighbours;
		}
		create zebra from: shape_file_zebra with:[density::float(read("BUFFERDIS"))*25]{
		//	color <-rnd_color(255);
			trajectory <- trajectory + location;
		}
		
		create wildebeest from: shape_file_wildebeest with: [density::float(read ("BUFFERDIS"))] {
	
	        
	    }
		
		//create  habitats from: shape_file_habitats with:[hab::string(read("HABITATS"))];	
		
		create park from: shape_file_park;
		
			

	}
			
		
			
	reflex computemeangreeness{
		meangreeness<-sum(grass accumulate(each.pcgreen))/(grass count (true));
		meanbiomass<-sum(grass accumulate(each.biomass))/(grass count (true));
		totalzebra<-sum(zebra accumulate(each.density));
		totalwildebeest<-sum(wildebeest accumulate(each.density));
		maxZebraDensity <- max(grass accumulate(each.zebra_density));
		maxWildebeestDensity <- max(grass accumulate(each.wildebeest_density));
	}		
	
				
}

	
species grass  {
	grass truc <- grass[331];
	bool show_neighbours <- false;
	bool highlighted <- false;
	float pcgreen ;
	float densityity <- 0.0;
	float carryingcapacity<-25000.0;
	float biomass;
	float growthrate<-1.05;
	rgb color_neighbours <- nil;
	rgb color <- °green ;
	list<grass>  neighbours <- [];
	float zebra_density <- 0.0;
	float wildebeest_density <- 0.0;
	
	
	aspect base {
		if (highlighted = false){
			draw shape color: color ;
		}else{
			draw shape color: °orange ;
		}
	}
	
	aspect zebra_density {
		draw rectangle(5000,5000) depth:100*zebra_density 
			color:rgb(255,int(240*(1-zebra_density/maxZebraDensity)),int(240*(1-zebra_density/maxZebraDensity))) 
		//	color:rgb(255,48*int(5*(1-zebra_density/maxZebraDensity)),48*int(5*(1-zebra_density/maxZebraDensity))) 
			border:rgb(255,int(255*(1-zebra_density/maxZebraDensity)),int(255*(1-zebra_density/maxZebraDensity)));
	}
	
	aspect wildebeest_density {
		draw rectangle(5000,5000) depth:100*zebra_density 
			color:rgb(int(240*(1-wildebeest_density/maxWildebeestDensity)),int(240*(1-wildebeest_density/maxWildebeestDensity)),255)
			border:rgb(int(255*(1-wildebeest_density/maxWildebeestDensity)),int(255*(1-wildebeest_density/maxWildebeestDensity)),255);
	}
	
	aspect base3d{
		draw rectangle(5000,5000) depth:biomass color: color border:color;
	}

	action define_neighbours{
		neighbours <- (self neighbours_at neighbours_range) of_species grass;
	}
	

	
	
	reflex growth {
		biomass<- max([biomass*exp(ln(growthrate)*(1-biomass/carryingcapacity)),20]);	
		color <- rgb(255 - int(255 * biomass/carryingcapacity),255,255 - int(255 * biomass/carryingcapacity));
	}
	
	
	reflex highlight_neighbours{
		if show_neighbours {
			color <- °blue;
			loop tmp over: neighbours {
				tmp.highlighted <- true;
			}
		}		
	}
	
	reflex count_density{
		zebra_density <- sum((agents_overlapping(self) of_species zebra) accumulate (each.density));
		wildebeest_density <- sum((agents_overlapping(self) of_species wildebeest) accumulate (each.density));

	}
	
	
	
	
}


species animal skills:[moving]{
	
	float density ;
	float grazing_efficiency;
	float active_met_rate;
	float beta;
	float weight;
	float alpha;
	float digestive_eff;
	grass	my_grass -> {first(agents_overlapping(self) of_species grass)};
	grass target <- my_grass;	
	list<point> trajectory <- [];
	bool follow <- false;
	rgb color;
	
	
	reflex move {
    	if follow{
			target.highlighted <- false;
		}
    	if (my_grass != nil){
			list<grass> potential_targets <- my_grass.neighbours;
			potential_targets <- potential_targets + my_grass;
			target <- potential_targets with_max_of (each.biomass);
		}
		
		do goto target:target speed: 1;
		do wander speed: 3;
		if follow{
			target.highlighted <- true;
			trajectory <- trajectory + location;
		}		
    }
	
	reflex eat_and_grow  { 
		float takeoff <- 0.0;
		if (my_grass != nil){
			 takeoff<- min([2*density*grazing_efficiency,my_grass.biomass]);
			 my_grass.biomass<-my_grass.biomass-takeoff;
		}
		float energy_gain <- alpha*digestive_eff*takeoff;
		float demography <- (beta*(energy_gain-active_met_rate*density)/weight);
		density<-0.9998*density + demography;
		if density < 0{
			do die;
		}
	}
	
	
	
	
	
}

species zebra  parent: animal{
	rgb color -> {follow ? °orange:°red};
	

	init{
		grazing_efficiency<-4.68;
		active_met_rate <- 19.28;
		beta <- 0.0365;
		weight <-200.0;
		alpha <-8.288;
		digestive_eff <-0.561;
	}
  

	aspect base {
		draw circle(320*sqrt(density))	color: color;	
		draw zebraIcon size:220*sqrt(density);
	}
	

	
	aspect base3d {
		if (my_grass != nil){
			draw circle(220*sqrt(density)) at:{location.x,location.y,my_grass.biomass*1.05}	color: color;	
		}else{
			draw circle(220*sqrt(density)) at:{location.x,location.y,0}	color: color;	
		}

	}
	
	aspect trajectory{
		if follow{
		  draw line(trajectory) color:color;	
		}	
	}
}



species wildebeest parent: animal{

	rgb color -> {follow ? °orange:°blue};

	init{
	grazing_efficiency <- 3.58;
	active_met_rate <- 17.07;
	beta <- 0.0365;
	weight <- 123.0;
	alpha <- 8.288;
	digestive_eff <- 0.648;
	}


	
	
	aspect base {
	  draw circle(600*sqrt(density))	color: color;
	  draw gnuIcon size:600*sqrt(density);
	}
	
	aspect base3d {
		if (my_grass != nil){
			draw circle(600*sqrt(density))	at:{location.x,location.y,my_grass.biomass*1.05} color: color;
		}else{
			draw circle(600*sqrt(density))	at:{location.x,location.y,0} color: color;
		}
	}
	
	aspect trajectory{
		if follow{
		  draw line(trajectory) color:color;	
		}	
	}
}



species agriculture  {
	string agric ;
	rgb color <- #brown;
	aspect base {
		draw shape color: color ;
	}
}


species park  {
	string park ;
	rgb color <- #pink;
	aspect base {
		draw shape color: color ;
	}
}

experiment Spmotion type: gui {
	parameter "Shapefile for the grass:" var: shape_file_grass category: "GIS" ;
	parameter "Shapefile for the zebra :" var: shape_file_zebra category: "GIS" ;
	parameter "Shapefile for the wildebeest:" var: shape_file_wildebeest category: "GIS" ;
	parameter "Shapefile for the agriculture:" var: shape_file_agriculture category: "GIS" ;
	parameter "Shapefile for the park:" var: shape_file_park category: "GIS" ;
	//parameter "Shapefile for the park:" var: shape_file_park category: "GIS" ;
	output {
		display Ecosystem_display  {
			species grass aspect: base ;
			species zebra aspect: base ;
			species zebra aspect:trajectory;
			species wildebeest aspect: base ;
			species wildebeest aspect: trajectory ;
			species agriculture aspect: base  transparency: 0.6;
			species park aspect: base transparency:0.7;
		}
		display zebra_densities type: opengl {
			species grass aspect: zebra_density ;
		}
		display wildebeest_densities type: opengl {
			species grass aspect: wildebeest_density ;
		}
		display Ecosystem_3D  type: opengl ambient_light:10 diffuse_light:100{
			species grass aspect: base3d ;
			species zebra aspect: base3d ;
			species wildebeest aspect: base3d ;
			species agriculture aspect: base  transparency: 0.6;
			species park aspect: base transparency:0.7;
		}	
		display population_information refresh_every: 5 {
			chart "Total populations" type: series{
				data "Zebra pop" value: totalzebra color: #red ;
				data "wildebeest" value:  totalwildebeest color: # blue;
			}
		}

		display grassgrowth_information refresh_every: 5 {
			chart "Total grassbiomass" type: series {
				data "Grass biomass" value: meanbiomass color: # green;
			}		
		}
  	}
}


		