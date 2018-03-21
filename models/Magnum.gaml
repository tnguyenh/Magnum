/**
* Name: Magnum
* Author: Magnum Team
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model Magnum

/* Insert your model definition here */

global{
	
	file boundary_shape_file <- file("../includes/gis/boundaries.shp");
	file area_shape_file <- file("../includes/gis/kajiado_ranch_2010.shp");
	file giraffe_shape_file <- file("../includes/gis/Giraffemean.shp");
	file zebra_wildebeest_file <-file("../includes/gis/WildebeestZebra.shp");
	file ndvi_file <- file("../includes/gis/Amboseli_Centroids_NDVI.shp");
	geometry shape <- envelope(area_shape_file);
	
	list<string> species_list <-["Zebra","Giraffe","Wildebeest"];
	map<string,rgb> species_colormap <- ["Zebra"::#purple,"Giraffe"::#yellow,"Wildebeest"::#brown];
	
	bool show_ndvi <- true;
	
	list<string> ranch_names;
	//float mean_ndvi;
	//list<float> mean_populations;
	map<string,float> correlations;
	
	init{
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
	}
	
	aspect base{draw shape color: °blue;}
	
	
	reflex statistics{
		loop sp over: species_list {
			//write sp;
			//write first(grid_cell).pop_densities;
			//write(grid_cell collect(each.pop_densities[sp]));
			correlations[sp] <- correlation(grid_cell collect(each.ndvi), grid_cell collect(each.pop_densities[sp]));
			write "Correlation for "+sp+": "+correlations[sp];
		}
		write " ";
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
		draw circle(sqrt(density)*500) color: species_colormap[species_name];
	}
	
	reflex move{
		do wander speed: 1000.0 bounds: first(boundary).shape;// bounds: geometry_collection(ranch collect(each.shape));
	}
}

species grid_cell {
	float ndvi <- 0;
	map<string,float> pop_densities<-["Zebra"::0,"Giraffe"::0,"Wildebeest"::0];
	geometry shape <- square(5#km);
	
	aspect ndvi{
		if show_ndvi{
			draw shape color: rgb(220-220*ndvi/10000,220,220-220*ndvi/10000);
		}
	}
	
	reflex compute_pop_densities{
		loop sp over: species_list{
			pop_densities[sp] <- sum((animal where(each.species_name = sp) overlapping self) accumulate (each.density));
		}
		//write 'essai'+pop_densities;
	}
}

experiment simulation type: gui {

	
	// Define parameters here if necessary
	parameter "Sow NDVI" category:"Display" var: show_ndvi;
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	
	output {
		
		display environment{
			species ranch aspect: base;
			species grid_cell aspect: ndvi;
			species animal aspect: base;
			//species boundary aspect: base;
		}
	}
}