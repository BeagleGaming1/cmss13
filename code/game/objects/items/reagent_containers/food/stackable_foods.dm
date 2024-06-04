/obj/item/reagent_container/food/snacks/stackable
	var/list/filling_states = list()
	///How many items can be put on the food
	var/max_stack_size = 0
	///Refs of ingredients placed on the food
	var/list/ingredients = list()
	///Typepaths of ingredients the food spawns with
	var/list/initial_ingredients = list()

/obj/item/reagent_container/food/snacks/stackable/Initialize()
	. = ..()
	for(var/obj/item/reagent_container/food/snacks/food as anything in initial_ingredients)
		add_ingredient(food)

/obj/item/reagent_container/food/snacks/stackable/Destroy()
	QDEL_NULL_LIST(ingredients)
	. = ..()

/obj/item/reagent_container/food/snacks/stackable/get_examine_text(mob/user)
	. = ..()
	if(max_stack_size)

/obj/item/reagent_container/food/snacks/stackable/update_icon()
	. = ..()
	overlays.Cut()

	for(var/obj/item/reagent_container/food/snacks/stackable/ingredient as anything in ingredients)
		var/image/new_ingredient = new(icon, "[pick(filling_states)]_")


/obj/item/reagent_container/food/snacks/stackable/attackby(obj/item/attacking_item, mob/user)
	. = ..()
	if(!istype(attacking_item, /obj/item/reagent_container/food/snacks))
		return

	if(istype(attacking_item, /obj/item/reagent_container/food/snacks/stackable))
		return

	if(max_stack_size && ingredients.len >= max_stack_size)
		to_chat(user, SPAN_WARNING("There are too many ingredients already on [src]."))
		return

	add_ingredient(attacking_item)

/obj/item/reagent_container/food/snacks/stackable/proc/add_ingredient(obj/item/reagent_container/food/snacks/food)
	food += ingredients
	food.forceMove(src)

/obj/item/reagent_container/food/snacks/stackable/sandwich
	name = "sandwich"
	desc = "The best thing since sliced bread."
	icon_state = "breadslice"
	bitesize = 2

