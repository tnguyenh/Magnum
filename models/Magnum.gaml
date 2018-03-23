/**
* Name: Magnum
* Author: Magnum Team
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model Magnum

/* Insert your model definition here */

global{
	// one cycle = 8 days;
	float step <- 8 #day;
	
	file boundary_shape_file <- file("../includes/gis/boundaries.shp");
	file area_shape_file <- file("../includes/gis/kajiado_ranch_2010.shp");
	file giraffe_shape_file <- file("../includes/gis/Giraffemean.shp");
	file zebra_wildebeest_file <-file("../includes/gis/WildebeestZebra.shp");
	file ndvi_file <- file("../includes/gis/Amboseli_Centroids_NDVI.shp");
	file ndvi_asc_file <- file("../includes/gis/mod13q1_ndvi_2000_273.txt");
	geometry shape <- envelope(area_shape_file);
	
	list<string> species_list <-["Zebra","Giraffe","Wildebeest"];
	map<string,rgb> species_colormap <- ["Zebra"::#purple,"Giraffe"::#yellow,"Wildebeest"::#brown];
	
	bool show_ndvi <- true;
	bool show_densities <- false;
	bool show_animal_data <- true;
	
	list<string> ranch_names;
	map<string,float> correlations;
	
	file animal_data_file <- file("../includes/gis/Animal_data/animals_utm.shp");
	date starting_date;
	date end_date;
	

	 
	
	init{		
//		ask cell {		
//			color <-rgb( (mntImageRaster) at {grid_x,grid_y}) ;
//		}
		
		
		create ranch from: area_shape_file with:[name::string(read("R_NAME"))]{
			self.color <- rnd_color(255);
		}
		
		create grid_cell from: ndvi_file with:[ndvi::float(read("MOD13Q1_ND"))]
		{
			
		}
		
		create boundary from: boundary_shape_file;
		
		ranch_names <- ranch collect(each.name);
		write ranch_names;
		write "There are "+ length(ranch_names) + " ranches.";
		
		create animal from:  giraffe_shape_file with: [density::float(read("Giraffe"))]{
			species_name <-"Giraffe"; 
		}
		 
		create animal from:  zebra_wildebeest_file with: [density::float(read("Zebra"))]{
			species_name<-"Zebra";
		}
		
		create animal from:  zebra_wildebeest_file with: [density::float(read("Wildebeest"))]{
			species_name<-"Wildebeest";
		}
		
		create animal_data from: animal_data_file with: 
				[//day::date(string(get("COUNT")),'d/M/yyyy'), 
				tmp::string(get("COUNT")),
				zebra_pop::float(get("Zebra")),
				wildebeest_pop::float(get("Wildebeest")),
				giraffe_pop::float(get("Giraffe"))]{
				write tmp;
		}
			
			
		starting_date <- first(animal_data).day;
//		write min(animal_data collect(each.day)); // min ne marche pas avec date, poster une issue Gama
		end_date <- last(animal_data).day;
		write "Start date: "+starting_date;
		write "End date: "+end_date;
		
	}
	
//	  reflex info_date {
//        write "current_date at cycle " + cycle + " : " + current_date;
//        if end_date<current_date{
//        	write "Simulation has ended.";
//        }
//    }
	
	
	reflex statistics{
//		loop sp over: species_list {
//			correlations[sp] <- correlation(grid_cell collect(each.ndvi), grid_cell collect(each.pop_densities[sp]));
//			write "Correlation for "+sp+": "+correlations[sp];
//		}
//		write " ";
	}



}



species ranch{
	string name;
	rgb color;
	
	aspect base{
		draw shape color: color;
	}	
}

species boundary{
	aspect base{
			draw shape color:°blue ;
	}	
}

species animal skills:[moving]{
	/* unit: herd  */
	string species_name <- "none";
	float density <- 0.0;
	float grazing_efficiency;
	ranch my_ranch;
	rgb color;
	
	aspect base{
		if !show_densities{
			draw circle(sqrt(density)*500) color: species_colormap[species_name];
		}
	}
	
	reflex move{
		do wander speed: 1000.0 bounds: first(boundary).shape;// bounds: geometry_collection(ranch collect(each.shape));
	
	
	
	}
	
	
}

species grid_cell {
	float ndvi <- 0.0;
	map<string,float> pop_densities<-["Zebra"::0.0,"Giraffe"::0.0,"Wildebeest"::0.0];
	geometry shape <- square(5#km);
	
	aspect ndvi{
		if show_ndvi{
			draw shape color: rgb(220-220*ndvi/10000,220,220-220*ndvi/10000);
		}
		if show_densities{
			loop sp over: species_list {
				if pop_densities[sp] > 0 {// sinon cela affiche un petit carre. Bug Gama ?
					draw circle(sqrt(pop_densities[sp])*500) color: species_colormap[sp];
				}
			}
		}
	}
	
//	reflex compute_pop_densities{
//		loop sp over: species_list{
//			pop_densities[sp] <- sum((animal where(each.species_name = sp) overlapping self) accumulate (each.density));
//		}
//	}
}


//grid cell file: ndvi_asc_file{
//	init {
//		color<- rgb(0,grid_value * 250/10000,0);
//	}
//}



species animal_data{
	date day;
	map<string,float> pop_count;
	float zebra_pop;
	float wildebeest_pop;
	float giraffe_pop;
	string tmp;
	
	aspect base{
		if false {//(day >= current_date) and (day < current_date + step) and (show_animal_data) {
			draw circle(sqrt(zebra_pop)*500) color: #red;//species_colormap["Zebra"];
			draw circle(sqrt(wildebeest_pop)*500) color: #red;// species_colormap["Wildebeest"];		
			draw circle(sqrt(giraffe_pop)*500) color: #red;//species_colormap["Giraffe"];	
		}
	}
}


experiment simulation type: gui {

	
	// Define parameters here if necessary
	parameter "Show NDVI" category:"Display" var: show_ndvi;
	parameter "Show animal densities" category:"Display" var: show_densities;
	parameter "Show animal data" category:"Display" var: show_animal_data;
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	
	output {
		
		display environment{
			
			species ranch aspect: base;
			species grid_cell aspect: ndvi;
			species animal aspect: base;
			species animal_data aspect: base;
	//		grid cell lines: rgb("black") ;
			//species boundary aspect: base;
		}
	}
}