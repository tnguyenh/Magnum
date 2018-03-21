/**
* Name: Magnum
* Author: Magnum Team
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model Magnum

/* Insert your model definition here */

global{
	file area_shape_file <- file("../includes/gis/kajiado_ranch_2010.shp");
	file giraffe_shape_file <- file("../includes/gis/Giraffemean.shp");
	geometry shape <- envelope(area_shape_file);
	list<string> ranch_names;
	
	init{
		create ranch from: area_shape_file with:[name::string(read("R_NAME"))]{
			self.color <- rnd_color(255);
		}
		
		ranch_names <- ranch collect(each.name);
		write ranch_names;
		write "There are "+ length(ranch_names) + " ranches.";
		
		create animal from:  giraffe_shape_file with: [density::float(read("Giraffe"))]{
			color <- °yellow;
		}
		
	}
	
	aspect base{draw shape color: °blue;}
	

}



species ranch{
	string name;
	rgb color;
	
	aspect base{
		draw shape color: color;
	}	
}


species animal skills:[moving]{
	/* unit: herd  */
	string species_name;
	float density <- 0;
	float grazing_efficiency;
	ranch my_ranch;
	rgb color;
	
	aspect base{
		draw circle(sqrt(density)*500) color: °yellow;

	}
	
	reflex move{
		do wander speed: 1000 bounds: world.shape;// bounds: geometry_collection(ranch collect(each.shape));
	}
	
}



experiment simulation type: gui {

	
	// Define parameters here if necessary
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	
	output {
		
		display environment{
			species ranch aspect: base;
			species animal aspect: base;
		}
	// Define inspectors, browsers and displays here
	
	// inspect one_or_several_agents;
	//
	// display "My display" { 
	//		species one_species;
	//		species another_species;
	// 		grid a_grid;
	// 		...
	// }

	}
}