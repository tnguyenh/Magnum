/**
* Name: Magnum
* Author: Magnum Team
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model Magnum

/* Model framework for Magnum */

global{
	// one cycle = 8 days;
	float step <- 8 #day;
	
	file boundary_shape_file <- file("../includes/gis/boundaries.shp");
	file GR_shape_file <- file("../includes/gis/kajiado_ranch_2010.shp");
	file giraffe_shape_file <- file("../includes/gis/Giraffemean.shp");
	file zebra_wildebeest_file <-file("../includes/gis/WildebeestZebra.shp");
	
	
	// ndvi files
	file ndvi_folder <-folder("../includes/gis/MODIS_ASCII");
	list<file> ndvi_files_list;
	
	file ndvi_file <- file("../includes/gis/Amboseli_Centroids_NDVI.shp");
	//file ndvi_asc_file <- file("../includes/gis/MODIS_ASCII/mod13q1_ndvi_2000_273.txt");
//	file test_ndvi_asc_file <- file("../includes/gis/MODIS_ASCII/mod13q1_ndvi_2000_273.asc");
//	file test_ndvi_asc_file <- grid_file("../includes/gis/MODIS_FOR_MODEL_RESAMPLE/test3_ascii_esri.asc");
	file ndvi_asc_file <- text_file("../includes/gis/MODIS_FOR_MODEL_RESAMPLE/test3_ascii_esri.asc");
	//file mntImageRaster <- image_file('../includes/gis/MODIS_FOR_MODEL_RESAMPLE/MOD13Q1_NDVI_2000_273.tif') ;
	//file mntImageRaster <- image_file('../includes/gis/MODIS_FOR_MODEL_RESAMPLE/test2.tif') ;
	int grid_width; //<- mntImageRaster.contents.columns; 
	int grid_height; //<-  mntImageRaster.contents.rows; 
	float xllcorner;
	float yllcorner;
	float cellsize;
	int NODATA_value <- -1;
	list<int> grid_dim <- load_asc_file_dimensions(ndvi_asc_file);
	geometry shape <- envelope(boundary_shape_file);
	
	list<string> species_list <-["Zebra","Giraffe","Wildebeest"];
	map<string,rgb> species_colormap <- ["Zebra"::#purple,"Giraffe"::#yellow,"Wildebeest"::#brown];
	map<string,int> month_to_int <- ["Jan"::1,"Feb"::2,"Mar"::3,"Apr"::4,"May"::5,"Jun"::6,"Jul"::7,"Aug"::8,"Sep"::9,"Oct"::10,"Nov"::11,"Dec"::12];
	
	bool show_ndvi <- true;
	bool show_densities <- false;
	bool show_animal_data <- true;
	
	list<string> ranch_names;
	map<string,float> correlations;
	
	file animal_data_file <- file("../includes/gis/Animal_data/animals_utm.shp");
	
	list<date> count_dates;
	date starting_date;
	date end_date;
	float neighbours_range <- 20.0#km;

	 
	
	init{		
		
		
		
		create ranch from: GR_shape_file with:[name::string(read("R_NAME"))]{
			self.color <- rnd_color(255);
		}
		
		create grid_cell from: ndvi_file with:[ndvi::float(read("MOD13Q1_ND"))]
		{
			
		}
		
		create boundary from: boundary_shape_file;
		
		ranch_names <- ranch collect(each.name);
		write "There are "+ length(ranch_names) + " ranches: "+ranch_names;
		
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
				[
				tmp::string(get("COUNT")),
				zebra_pop::float(get("Zebra")),
				wildebeest_pop::float(get("Wildebeest")),
				giraffe_pop::float(get("Giraffe")),
				pos_x::float(get("X_utm")),
				pos_y::float(get("Y_utm"))]{
			int year <- replace_regex(tmp,'.* ','') as int;
			int month <- month_to_int[copy_between(tmp,4,7)];
			int day <- copy_between(tmp,8,10) as int;
			count_day <- date([year,month,day]);
		}

		count_dates <- animal_data collect(each.count_day);
		starting_date <- first(animal_data).count_day;
		end_date <- first(animal_data).count_day;
		
		loop tmp over: count_dates{
			if tmp < starting_date{
				starting_date <- tmp;
			}
			if tmp > end_date{
				end_date <- tmp;
			}
			
		}
//		write min(animal_data collect(each.day)); // min ne marche pas avec date, poster une issue Gama
		write "Start date: "+starting_date;
		write "End date: "+end_date;
		
		list<string> tmp <- ndvi_folder.contents; // does not work without that temporary variable ????
		write first(tmp);
		ndvi_files_list <-  tmp collect(file(string(ndvi_folder)+"\\"+each)) where (each.extension="txt");	
		write ndvi_files_list;
		
		do load_asc_file(ndvi_asc_file);
		
        ask cell {		
			do  define_neighbours;

	}
	
	
	
	
	}
	
	
	
	
	
	  reflex info_date {
        write "current_date at cycle " + cycle + " : " + current_date;
        if end_date<current_date{
        	write "Simulation has ended.";
        	do halt;
        }
        
    }
	
	
	reflex statistics{
//		loop sp over: species_list {
//			correlations[sp] <- correlation(grid_cell collect(each.ndvi), grid_cell collect(each.pop_densities[sp]));
//			write "Correlation for "+sp+": "+correlations[sp];
//		}
//		write " ";
	}
	
	
	
	int load_asc_file(file f){
		int j <- 0;
		list<string> tmp; 	
		
		loop el over: f {
            if (el != "") {
	        	tmp <- split_with(el as string,' ');
	        	switch tmp[0]{
	            	match 'ncols' {grid_width <- tmp[1] as int;}
	            	match 'nrows' {grid_height <- tmp[1] as int;}
	            	match 'xllcorner' {xllcorner <- tmp[1] as float;}
	            	match 'yllcorner' {yllcorner <- tmp[1] as float;}
	            	match 'cellsize' {cellsize <- tmp[1] as float;}
	            	match 'NODATA_value' {NODATA_value <- tmp[1] as int;}
	            	default {
	            		loop i from: 0 to: length(tmp)-1{
	            			ask cell grid_at {i,j}{
	            				float tmp2 <- int(tmp[i])/350;
	            				color <-rgb(0,tmp2,0) ;
	            				ndvi <- int(tmp[i]);
	            			} 
	            		}
	            		j <- j + 1;		
	            	}
	            }
	        }
        }
        
		return 0;
	}
	
	
	list<int> load_asc_file_dimensions(file f){
		return [at(split_with(f[0] as string,' '),1) as int,at(split_with(f[1] as string,' '),1) as int];
	}
	
	

}



species ranch{
	string name;
	rgb color;
	
	aspect base{
		draw shape color: color;
	}	
	
	aspect borders{
		draw 200 around shape color: °white;
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
	cell	my_cell -> {first(agents_overlapping(self) of_species cell)};
	cell target <- my_cell;	
	list<point> trajectory <- [];
	bool follow <- false;
	
	rgb color;
	
	aspect base{
		if !show_densities{
			draw circle(sqrt(density)*500) color: species_colormap[species_name];
		}
	}
	
	
	reflex move {
    	//if follow{
			//target.highlighted <- false;
		//}
    	if (my_cell != nil){
			list<cell> potential_targets <- my_cell.neighbours;
			potential_targets <- potential_targets + my_cell;
			target <- potential_targets with_max_of (each.ndvi);
		}
		
		do goto target:target speed:  5 #km/#day;
		do wander speed: 0.5 #km/#day;
		//if follow{
			//target.highlighted <- true;
			//trajectory <- trajectory + location;
		//}		
    }
	
	
	
	
	
	//reflex move{
		
		
		
		//do wander speed: 5 #km/#day;//3000.0;// bounds: first(boundary).shape;// bounds: geometry_collection(ranch collect(each.shape));
	//}
}





species grid_cell {
	float ndvi <- 0.0;
	map<string,float> pop_densities<-["Zebra"::0.0,"Giraffe"::0.0,"Wildebeest"::0.0];
	geometry shape <- square(5#km);
	bool show_neighbours <- false;
	list<grid_cell>  neighbours <- [];
	
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








//grid cell file: test_ndvi_asc_file{
//	int scale <-250;
//	init {
//		color<- rgb(grid_value/scale,grid_value/scale,grid_value/scale);
//	}
//}

grid cell width: grid_dim[0] height: grid_dim[1]{
	float ndvi <- 0.0;
	bool highlighted <- false;
	bool show_neighbours <- false;
	list<cell>  neighbours <- [];
	
	action define_neighbours{
		neighbours <-  neighbors_of(topology(self),self,8) ;
	}
	
}




species animal_data{
	date count_day;
	map<string,float> pop_count;
	float zebra_pop;
	float wildebeest_pop;
	float giraffe_pop;
	string tmp;
	
	float pos_x;
	float pos_y;
	
	aspect base{
		//if (count_day >= current_date) and (count_day < current_date + step) and (show_animal_data) {
		if (count_day = count_dates last_with(each <= current_date)) and (show_animal_data) {
			draw 500 around circle(sqrt(zebra_pop)*500) color: species_colormap["Zebra"];//species_colormap["Zebra"];
			draw 500 around circle(sqrt(wildebeest_pop)*500) color: species_colormap["Wildebeest"];// species_colormap["Wildebeest"];		
			draw 500 around circle(sqrt(giraffe_pop)*500) color: species_colormap["Giraffe"];//species_colormap["Giraffe"];	
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
			
			grid cell;// lines: rgb("black") ;
			species ranch aspect: borders;
			//species grid_cell aspect: ndvi;
			species animal aspect: base;
			//species animal_data aspect: base;
		//	species boundary aspect: base;
		}
	}
}