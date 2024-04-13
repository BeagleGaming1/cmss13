/* * * * * * * * * * * * * * * * * * * * * * * * * *
 * /datum/recipe by rastaf0 13 apr 2011 *
 * * * * * * * * * * * * * * * * * * * * * * * * * */

///The recipe has exactly the amount of ingredients it needs
#define RECIPES_INGREDIENTS_CORRECT 0 //1
///The recipe has too many ingredients
#define RECIPES_INGREDIENTS_HIGH 1 //-1
///The recipe doesn't have enough ingredients
#define RECIPES_INGREDIENTS_LOW 2 //0

/datum/recipe
	///A list of all items the recipe needs, by the items typepath
	var/list/required_ingredients // place /foo/bar before /foo
	///A list of all chemicals the recipe needs, by the reagents id
	var/list/required_chemicals //example: list("berryjuice" = 5) // do not list same reagent twice
	///The typepath of the resulting item
	var/obj/result

	///Default time it takes for the recipe to be cooked
	var/time = 15 SECONDS
	//what kind of cooking is required to make this recipe
	var/cooking_type = COOKING_TYPE_ALL_RECIPES //TEMP REMOVE THIS REMOVE THIS
	///The abstract parent type that shouldnt be available itself in recipes
	var/abstract_type = /datum/recipe


///Check if the machine has correct reagents
/datum/recipe/proc/check_reagents(datum/component/cooking/cooking)
	if(!required_chemicals) //if no chems in the recipe, skip it
		return RECIPES_INGREDIENTS_CORRECT

	var/datum/reagents/reagent_holder = new(INFINITY) //just hold everything for now
	for(var/obj/item/item as anything in cooking.ingredients)
		for(var/datum/reagent/current_reagent in item.reagents.reagent_list)
			reagent_holder.add_reagent(current_reagent.id, current_reagent.volume)

	if(required_chemicals.len < reagent_holder.reagent_list.len) //if less chems
		qdel(reagent_holder)
		return RECIPES_INGREDIENTS_LOW

	for(var/chem_ingredient in required_chemicals) //loop through every chem required in the recipe
		var/chem_amount = reagent_holder.get_reagent_amount(chem_ingredient) //If the chem is in the reagent storage, get the amount
		var/chem_diff = abs(chem_amount - required_chemicals[chem_ingredient]) //the difference between how many units are required and had

		if((chem_diff > 0.1)) //floating point
			continue

		qdel(reagent_holder)
		if(chem_amount > required_chemicals[chem_ingredient]) //Whether theres too much or not enough
			return RECIPES_INGREDIENTS_HIGH
		return RECIPES_INGREDIENTS_LOW

	qdel(reagent_holder)
	return RECIPES_INGREDIENTS_CORRECT

///Check if the machine has correct ingredients
/datum/recipe/proc/check_items(datum/component/cooking/cooking)
	if(!required_ingredients) //if no ingredients
		if(cooking.ingredients.len) //check for anything in the ingredients list
			return RECIPES_INGREDIENTS_HIGH //if unneeded ingredients
		return RECIPES_INGREDIENTS_LOW

	var/list/ingredients_list = required_ingredients.Copy()
	for(var/obj/ingredient as anything in cooking.ingredients)
		var/found = FALSE

		for(var/ingredient_type in ingredients_list)
			if(!istype(ingredient, ingredient_type))
				continue

			ingredients_list -= ingredient_type //if you have the correct ingredient, remove it from the list
			found = TRUE
			break

		if(!found) //if an ingredient is missing
			return RECIPES_INGREDIENTS_LOW

	if(ingredients_list.len) //if theres anything left, theres not enough ingredients
		return RECIPES_INGREDIENTS_LOW

	return RECIPES_INGREDIENTS_CORRECT

///Create an item and transfer reagents to it
/datum/recipe/proc/make(mob/user, datum/component/cooking/cooking)
	var/obj/result_obj = new result() //make the new item
	if(istype(result_obj, /obj/item/reagent_container/food/snacks)) //if its a food item, skip to the food specific one
		var/food_result = make_food(result_obj, user, cooking)
		if(food_result)
			return food_result

	for(var/i in 1 to cooking.ingredients.len)
		var/obj/ingredient = cooking.remove_last_ingredient()
		if(!ingredient)
			continue

		ingredient.reagents.trans_to(result_obj, ingredient.reagents.total_volume) //add chemicals from ingredient
		qdel(ingredient) //remove the ingredient

	result_obj = apply_additional_effects(result_obj, user)
	return result_obj

///Create food and transfer reagents to it
/datum/recipe/proc/make_food(obj/item/reagent_container/food/snacks/result_obj, mob/user, datum/component/cooking/cooking)
	if(!istype(result_obj))
		CRASH("[result_obj] with the path [result_obj.type] was passed to make_food despite not being a subtype of /obj/item/reagent_container/food/snacks.")
	var/name_finalized = FALSE //incase it gets a unique name

	for(var/i in 1 to cooking.ingredients.len)
		var/obj/ingredient = cooking.remove_last_ingredient()
		if(!ingredient)
			continue

		if(ingredient.reagents)
			ingredient.reagents.del_reagent("nutriment") //remove any extra nutrient
			ingredient.reagents.update_total()
			ingredient.reagents.trans_to(result_obj, ingredient.reagents.total_volume) //transfer everything else into the result

		if(!name_finalized)
			if(istype(ingredient, /obj/item/reagent_container/food/snacks))
				var/obj/item/reagent_container/food/snacks/food_ingredient = ingredient
				if(food_ingredient.made_from_player) //ie human or xeno meat
					result_obj.name = food_ingredient.made_from_player + result_obj.name
					result_obj.set_origin_name_prefix(food_ingredient.made_from_player) //apply the special name to the food
					name_finalized = TRUE

		qdel(ingredient) //remove the ingredient

	result_obj = apply_additional_effects(result_obj, user, TRUE)
	return result_obj

///Picks the correct recipe out of the recipes list and returns it
/datum/component/cooking/proc/select_recipe(list/datum/recipe/available_recipes, datum/component/cooking/cooking, mob/user)

	var/list/datum/recipe/possible_recipes = new

	for(var/datum/recipe/recipe as anything in available_recipes)
		if(!(recipe.cooking_type in cooking.cooking_flags))
			continue

		if(recipe.check_reagents(cooking) == RECIPES_INGREDIENTS_CORRECT && recipe.check_items(cooking) == RECIPES_INGREDIENTS_CORRECT)
			possible_recipes += recipe //If the machine has all the required parts

	if(!possible_recipes.len) //No recipes
		return

	if(possible_recipes.len == 1) //Only one recipe, skip selection
		return possible_recipes[1]

	var/max_ingredients = 0
	var/max_reagents = 0

	var/ingredient_amount = 0
	var/reagent_amount = 0

	var/datum/recipe/selected_recipe

	for(var/datum/recipe/recipe in possible_recipes) //Select the most complicated recipe
		ingredient_amount = (recipe.required_ingredients) ? (recipe.required_ingredients.len) : 0
		reagent_amount = (recipe.required_chemicals) ? (recipe.required_chemicals.len) : 0

		if(ingredient_amount != max_ingredients) //too many ingredients
			continue

		if(reagent_amount <= max_reagents) //not enough chemicals
			continue

		if(!selected_recipe.additional_prerequsites(user)) //special cases
			continue

		max_ingredients = ingredient_amount //correct amount of ingredients and good enough chems
		max_reagents = reagent_amount
		selected_recipe = recipe

	return selected_recipe

///Skip selecting recipe if there are additional requirements
/datum/recipe/proc/additional_prerequsites(mob/user)
	return TRUE

///If the result has any unique effects when completed
/datum/recipe/proc/apply_additional_effects(obj/result, mob/user, is_food = FALSE)
	return result

#undef RECIPES_INGREDIENTS_LOW
#undef RECIPES_INGREDIENTS_HIGH
#undef RECIPES_INGREDIENTS_CORRECT

/*
TODO:
- Sandwich height cap
- Refactor reagent_container init
- Refactor reagent application on init

- Delete gibber
-- Cut up corpses for meat
- Processor
-- Rework recipes

- Pots
- Pans
-- TF2 sound effect
- Spatula
- Ladle
- Plate
- Knives
- Forks
- Spoons

- Burgers
- Pizza
- Pies
- Cake
- Eggs
- Soup
- Donuts
- Kebab
- Fries
- Fortune Cookies
- Meats
- Sandwiches
- Bread
- Salad
- Cheese
*/

///datum/recipe/plainburger
//	items = list(
//		/obj/item/reagent_container/food/snacks/bun,
//		/obj/item/reagent_container/food/snacks/meat,
//	)
//	result = /obj/item/reagent_container/food/snacks/monkeyburger

///datum/recipe/jellyburger
//	reagents = list("cherryjelly" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/bun,
//	)
//	result = /obj/item/reagent_container/food/snacks/jellyburger/cherry

///datum/recipe/xenoburger
//	items = list(
//		/obj/item/reagent_container/food/snacks/bun,
//		/obj/item/reagent_container/food/snacks/meat/xenomeat,
//	)
//	result = /obj/item/reagent_container/food/snacks/xenoburger

///datum/recipe/fishburger
//	items = list(
//		/obj/item/reagent_container/food/snacks/bun,
//		/obj/item/reagent_container/food/snacks/carpmeat,
//	)
//	result = /obj/item/reagent_container/food/snacks/fishburger

///datum/recipe/tofuburger
//	items = list(
//		/obj/item/reagent_container/food/snacks/bun,
//		/obj/item/reagent_container/food/snacks/tofu,
//	)
//	result = /obj/item/reagent_container/food/snacks/tofuburger

///datum/recipe/human/burger
//	items = list(
//		/obj/item/reagent_container/food/snacks/meat/human,
//		/obj/item/reagent_container/food/snacks/bun,
//	)
//	result = /obj/item/reagent_container/food/snacks/human/burger

///datum/recipe/brainburger
//	items = list(
//		/obj/item/reagent_container/food/snacks/bun,
//		/obj/item/organ/brain,
//	)
//	result = /obj/item/reagent_container/food/snacks/brainburger

//weird burger lot's of them are LRP directly picked from bs12 food port stuff

///datum/recipe/roburger
//	items = list(
//		/obj/item/reagent_container/food/snacks/bun,
//		/obj/item/fake_robot_head,
//	)
//	result = /obj/item/reagent_container/food/snacks/roburger

///datum/recipe/clownburger
//	items = list(
//		/obj/item/reagent_container/food/snacks/bun,
//		/obj/item/clothing/mask/gas/clown_hat,
//		/* /obj/item/reagent_container/food/snacks/grown/banana, */
//	)
//	result = /obj/item/reagent_container/food/snacks/clownburger

///datum/recipe/mimeburger
//	items = list(
//		/obj/item/reagent_container/food/snacks/bun,
//		/obj/item/clothing/head/beret,
//	)
//	result = /obj/item/reagent_container/food/snacks/mimeburger

//Big burger the base require other burger.

///datum/recipe/superbiteburger
//	reagents = list("sodiumchloride" = 5, "blackpepper" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/bigbiteburger,
//		/obj/item/reagent_container/food/snacks/bun,
//		/obj/item/reagent_container/food/snacks/meat,
//		/obj/item/reagent_container/food/snacks/grown/tomato,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//		/obj/item/reagent_container/food/snacks/boiledegg,
//	)
//	result = /obj/item/reagent_container/food/snacks/superbiteburger

///datum/recipe/bigbiteburger
//	items = list(
//		/obj/item/reagent_container/food/snacks/monkeyburger,
//		/obj/item/reagent_container/food/snacks/meat,
//		/obj/item/reagent_container/food/snacks/egg,
//	)
//	result = /obj/item/reagent_container/food/snacks/bigbiteburger

//Bread the base of bread is a dough.

/datum/recipe/bread
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/dough,
	)

	result = /obj/item/reagent_container/food/snacks/sliceable/bread

///datum/recipe/creamcheesebread
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/creamcheesebread

///datum/recipe/tofubread
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/tofu,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/tofubread

/datum/recipe/xenomeatbread
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/meat/xenomeat,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)

	result = /obj/item/reagent_container/food/snacks/sliceable/xenomeatbread

///datum/recipe/bananabread
//	reagents = list("milk" = 5, "sugar" = 15)
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/grown/banana,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/bananabread

/datum/recipe/meatbread
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)

	result = /obj/item/reagent_container/food/snacks/sliceable/meatbread

//Pizza the base is a flatdough and a 5u of tomato.

/datum/recipe/pizza
	required_chemicals = list(
		"tomatojuice" = 5
	)
	abstract_type = /datum/recipe/pizza

///datum/recipe/pizza/pizzamargherita
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/pizza/margherita

///datum/recipe/pizza/mushroompizza
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/grown/mushroom,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/pizza/mushroompizza

///datum/recipe/pizza/vegetablepizza
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/grown/eggplant,
//		/obj/item/reagent_container/food/snacks/grown/carrot,
//		/obj/item/reagent_container/food/snacks/grown/corn,
//		/obj/item/reagent_container/food/snacks/grown/tomato,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/pizza/vegetablepizza

///datum/recipe/pizza/meatpizza
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/meat,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/pizza/meatpizza

//Tart as a base with flatdough, egg, 5milk, 5sugar

/datum/recipe/appletart //TODO: regular / gold separate
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/grown/goldapple,
	)
	required_chemicals = list(
		"sugar" = 5,
		"milk" = 5
	)

	result = /obj/item/reagent_container/food/snacks/appletart

///datum/recipe/pumpkinpie
//	reagents = list("milk" = 5, "sugar" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/grown/pumpkin,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/pumpkinpie

//Pie as a base with flatdough

///datum/recipe/amanita_pie
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/grown/mushroom/amanita,
//	)
//	result = /obj/item/reagent_container/food/snacks/amanita_pie

///datum/recipe/plump_pie
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/grown/mushroom/plumphelmet,
//	)
//	result = /obj/item/reagent_container/food/snacks/plump_pie

///datum/recipe/tofupie
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/tofu,
//	)
//	result = /obj/item/reagent_container/food/snacks/tofupie

///datum/recipe/xemeatpie
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/meat/xenomeat,
//	)
//	result = /obj/item/reagent_container/food/snacks/xemeatpie

///datum/recipe/meatpie
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/meat,
//	)
//	result = /obj/item/reagent_container/food/snacks/meatpie

/datum/recipe/pie
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/grown/banana,
	)
	required_chemicals = list(
		"sugar" = 5
	)

	result = /obj/item/reagent_container/food/snacks/pie

///datum/recipe/cherrypie
//	reagents = list("sugar" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/grown/cherries,
//	)
//	result = /obj/item/reagent_container/food/snacks/cherrypie

///datum/recipe/applepie
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//		/obj/item/reagent_container/food/snacks/grown/apple,
//	)
//	result = /obj/item/reagent_container/food/snacks/applepie

//Cake as a base of a dough, 5milk, 5sugar

/datum/recipe/cake
	required_chemicals = list(
		"milk" = 5,
		"sugar" = 15
	)
	abstract_type = /datum/recipe/cake

///datum/recipe/cake/plaincake
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/egg,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/plaincake

///datum/recipe/cake/birthdaycake
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/clothing/head/cakehat,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/birthdaycake

///datum/recipe/cake/applecake
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/grown/apple,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/applecake

///datum/recipe/cake/braincake
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/organ/brain,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/braincake

///datum/recipe/cake/orangecake
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/grown/orange,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/orangecake

///datum/recipe/cake/limecake
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/grown/lime,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/limecake

///datum/recipe/cake/lemoncake
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/grown/lemon,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/lemoncake

///datum/recipe/cake/chocolatecake
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/chocolatebar,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/chocolatecake

///datum/recipe/cake/carrotcake
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/grown/carrot,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/carrotcake

///datum/recipe/cake/cheesecake
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/cheesecake

//egg the base is an egg

///datum/recipe/chocolateegg
//	items = list(
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/chocolatebar,
//	)
//	result = /obj/item/reagent_container/food/snacks/chocolateegg

///datum/recipe/friedegg
//	reagents = list("sodiumchloride" = 1, "blackpepper" = 1)
//	items = list(
//		/obj/item/reagent_container/food/snacks/egg,
//	)
//	result = /obj/item/reagent_container/food/snacks/friedegg

///datum/recipe/boiledegg
//	reagents = list("water" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/egg,
//	)
//	result = /obj/item/reagent_container/food/snacks/boiledegg

///datum/recipe/omelette
//	items = list(
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/omelette

//Spaghetti the base is spagetti and 5 water.

/datum/recipe/spagetti
	required_chemicals = list(
		"water" = 5
	)
	abstract_type = /datum/recipe/spagetti

///datum/recipe/spagetti/boiledspagetti
//	items = list(
//		/obj/item/reagent_container/food/snacks/spagetti,
//	)
//	result = /obj/item/reagent_container/food/snacks/boiledspagetti

///datum/recipe/spagetti/pastatomato
//	items = list(
//		/obj/item/reagent_container/food/snacks/spagetti,
//		/obj/item/reagent_container/food/snacks/grown/tomato,
//	)
//	result = /obj/item/reagent_container/food/snacks/pastatomato

///datum/recipe/spagetti/meatballspagetti
//	items = list(
//		/obj/item/reagent_container/food/snacks/spagetti,
//		/obj/item/reagent_container/food/snacks/meatball,
//	)
//	result = /obj/item/reagent_container/food/snacks/meatballspagetti

///datum/recipe/spagetti/spesslaw
//	items = list(
//		/obj/item/reagent_container/food/snacks/spagetti,
//		/obj/item/reagent_container/food/snacks/meatball,
//		/obj/item/reagent_container/food/snacks/meatball,
//	)
//	result = /obj/item/reagent_container/food/snacks/spesslaw

//Soup the base for a soup is 10 water

//datum/recipe/meatballsoup
//	reagents = list("water" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/meatball,
//		/obj/item/reagent_container/food/snacks/grown/carrot,
//		/obj/item/reagent_container/food/snacks/grown/potato,
//	)
//	result = /obj/item/reagent_container/food/snacks/meatballsoup

///datum/recipe/vegetablesoup
//	reagents = list("water" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/grown/carrot,
//		/obj/item/reagent_container/food/snacks/grown/corn,
//		/obj/item/reagent_container/food/snacks/grown/eggplant,
//		/obj/item/reagent_container/food/snacks/grown/potato,
//	)
//	result = /obj/item/reagent_container/food/snacks/vegetablesoup

///datum/recipe/nettlesoup
//	reagents = list("water" = 10)
//	items = list(
//		/obj/item/grown/nettle,
//		/obj/item/reagent_container/food/snacks/grown/potato,
//		/obj/item/reagent_container/food/snacks/egg,
//	)
//	result = /obj/item/reagent_container/food/snacks/nettlesoup

///datum/recipe/wishsoup
//	reagents = list("water" = 20)
//	result= /obj/item/reagent_container/food/snacks/wishsoup

///datum/recipe/tomatosoup
//	reagents = list("water" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/grown/tomato,
//	)
//	result = /obj/item/reagent_container/food/snacks/tomatosoup

///datum/recipe/milosoup
//	reagents = list("water" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/soydope,
//		/obj/item/reagent_container/food/snacks/tofu,
//	)
//	result = /obj/item/reagent_container/food/snacks/milosoup

///datum/recipe/bloodsoup
//	reagents = list("blood" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/grown/bloodtomato,
//	)
//	result = /obj/item/reagent_container/food/snacks/bloodsoup

///datum/recipe/mysterysoup
//	reagents = list("water" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/badrecipe,
//		/obj/item/reagent_container/food/snacks/tofu,
//		/obj/item/reagent_container/food/snacks/egg,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/mysterysoup

///datum/recipe/mushroomsoup
//	reagents = list("water" = 5, "milk" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/grown/mushroom/chanterelle,
//	)
//	result = /obj/item/reagent_container/food/snacks/mushroomsoup

///datum/recipe/beetsoup
//	reagents = list("water" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/grown/whitebeet,
//		/obj/item/reagent_container/food/snacks/grown/cabbage,
//	)
//	result = /obj/item/reagent_container/food/snacks/beetsoup

//Donut the base is dough //maybe change this to slice of flat dough to be more in check with quantity use compare to a bread

/datum/recipe/donut
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/doughslice,
	)
	required_chemicals = list(
		"sugar" = 5
	)

	result = /obj/item/reagent_container/food/snacks/donut/normal

///datum/recipe/chaosdonut
//	reagents = list("frostoil" = 5, "hotsauce" = 5, "sugar" = 5) //frostoil aka coldsauce
//	items = list(
//		/obj/item/reagent_container/food/snacks/doughslice,
//	)
//	result = /obj/item/reagent_container/food/snacks/donut/chaos

///datum/recipe/jellydonut
//	reagents = list("berryjuice" = 5, "sugar" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/doughslice,
//	)
//	result = /obj/item/reagent_container/food/snacks/donut/jelly

///datum/recipe/jellydonut/cherry
//	reagents = list("cherryjelly" = 5, "sugar" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/doughslice,
//	)
//	result = /obj/item/reagent_container/food/snacks/donut/cherryjelly

//other

///datum/recipe/hotdog
//	items = list(
//		/obj/item/reagent_container/food/snacks/bun,
//		/obj/item/reagent_container/food/snacks/sausage,
//	)
//	result = /obj/item/reagent_container/food/snacks/hotdog

///datum/recipe/waffles
//	reagents = list("sugar" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/doughslice,
//		/obj/item/reagent_container/food/snacks/doughslice,
//	)
//	result = /obj/item/reagent_container/food/snacks/waffles

///datum/recipe/pancakes
//	reagents = list("milk" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/doughslice,
//		/obj/item/reagent_container/food/snacks/doughslice,
//		/obj/item/reagent_container/food/snacks/doughslice,
//	)
//	result = /obj/item/reagent_container/food/snacks/pancakes

///datum/recipe/donkpocket
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//		/obj/item/reagent_container/food/snacks/meatball,
//	)
//	result = /obj/item/reagent_container/food/snacks/donkpocket //SPECIAL
//
///datum/recipe/donkpocket/proc/warm_up(obj/item/reagent_container/food/snacks/donkpocket/being_cooked)
//	being_cooked.warm = 1
//	being_cooked.reagents.add_reagent("tricordrazine", 5)
//	being_cooked.bitesize = 6
//	being_cooked.name = "Warm " + being_cooked.name
//	being_cooked.cooltime()
//
///datum/recipe/donkpocket/make_food(obj/container as obj)
//	var/obj/item/reagent_container/food/snacks/donkpocket/being_cooked = ..(container)
//	warm_up(being_cooked)
//	return being_cooked
//
///datum/recipe/donkpocket/warm
//	reagents = list() //This is necessary since this is a child object of the above recipe and we don't want donk pockets to need flour
//	items = list(
//		/obj/item/reagent_container/food/snacks/donkpocket,
//	)
//	result = /obj/item/reagent_container/food/snacks/donkpocket //SPECIAL
//
///datum/recipe/donkpocket/warm/make_food(obj/container as obj)
//	var/obj/item/reagent_container/food/snacks/donkpocket/being_cooked = locate() in container
//	if(being_cooked && !being_cooked.warm)
//		warm_up(being_cooked)
//	return being_cooked

/datum/recipe/muffin
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/doughslice,
	)
	required_chemicals = list(
		"milk" = 5,
		"sugar" = 5
	)

	result = /obj/item/reagent_container/food/snacks/muffin

/datum/recipe/eggplantparm
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/grown/eggplant,
	)

	result = /obj/item/reagent_container/food/snacks/eggplantparm

/datum/recipe/soylentviridians
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/grown/soybeans,
	)

	result = /obj/item/reagent_container/food/snacks/soylentviridians

/datum/recipe/soylentgreen
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/meat/human,
	)
	result = /obj/item/reagent_container/food/snacks/soylentgreen

/datum/recipe/berryclafoutis
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/grown/berries,
	)
	result = /obj/item/reagent_container/food/snacks/berryclafoutis

/datum/recipe/wingfangchu
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/meat/xenomeat,
	)
	required_chemicals = list(
		"soysauce" = 5
	)

	result = /obj/item/reagent_container/food/snacks/wingfangchu

///datum/recipe/human/kabob
//	items = list(
//		/obj/item/stack/rods,
//		/obj/item/reagent_container/food/snacks/meat/human,
//	)
//	result = /obj/item/reagent_container/food/snacks/human/kabob

///datum/recipe/monkeykabob
//	items = list(
//		/obj/item/stack/rods,
//		/obj/item/reagent_container/food/snacks/meat/monkey,
//	)
//	result = /obj/item/reagent_container/food/snacks/monkeykabob

///datum/recipe/syntikabob
//	items = list(
//		/obj/item/stack/rods,
//		/obj/item/reagent_container/food/snacks/meat/synthmeat,
//	)
//	result = /obj/item/reagent_container/food/snacks/monkeykabob

///datum/recipe/tofukabob
//	items = list(
//		/obj/item/stack/rods,
//		/obj/item/reagent_container/food/snacks/tofu,
//	)
//	result = /obj/item/reagent_container/food/snacks/tofukabob

/datum/recipe/loadedbakedpotato
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/grown/potato,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)

	result = /obj/item/reagent_container/food/snacks/loadedbakedpotato

///datum/recipe/cheesyfries
//	items = list(
//		/obj/item/reagent_container/food/snacks/fries,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/cheesyfries

/datum/recipe/cubancarp
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/grown/chili,
		/obj/item/reagent_container/food/snacks/carpmeat,
	)

	result = /obj/item/reagent_container/food/snacks/cubancarp

/datum/recipe/popcorn
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/grown/corn,
	)

	result = /obj/item/reagent_container/food/snacks/popcorn

/datum/recipe/cookie
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/doughslice,
		/obj/item/reagent_container/food/snacks/chocolatebar,
	)
	required_chemicals = list(
		"milk" = 5,
		"sugar" = 5
	)

	result = /obj/item/reagent_container/food/snacks/cookie

///datum/recipe/fortunecookie
//	reagents = list("sugar" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/doughslice,
//	)
//	result = /obj/item/reagent_container/food/snacks/fortunecookie

///datum/recipe/fortunecookiefilled
//	reagents = list("sugar" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/doughslice,
//		/obj/item/paper,
//	)
//	result = /obj/item/reagent_container/food/snacks/fortunecookie/prefilled

///datum/recipe/meatsteak
//	reagents = list("sodiumchloride" = 1, "blackpepper" = 1)
//	items = list(
//		/obj/item/reagent_container/food/snacks/meat,
//	)
//	result = /obj/item/reagent_container/food/snacks/meatsteak

/datum/recipe/spacylibertyduff
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/grown/mushroom/libertycap,
	)
	required_chemicals = list(
		"water" = 5,
		"vodka" = 5
	)

	result = /obj/item/reagent_container/food/snacks/spacylibertyduff

/datum/recipe/amanitajelly
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/grown/mushroom/amanita,
	)
	required_chemicals = list(
		"water" = 5,
		"vodka" = 5
	)

	result = /obj/item/reagent_container/food/snacks/amanitajelly

/datum/recipe/amanitajelly/make_food(obj/container as obj)
	var/obj/item/reagent_container/food/snacks/amanitajelly/being_cooked = ..(container)
	being_cooked.reagents.del_reagent("amatoxin")
	return being_cooked

///datum/recipe/hotchili
//	items = list(
//		/obj/item/reagent_container/food/snacks/meat,
//		/obj/item/reagent_container/food/snacks/grown/chili,
//		/obj/item/reagent_container/food/snacks/grown/tomato,
//	)
//	result = /obj/item/reagent_container/food/snacks/hotchili

///datum/recipe/coldchili
//	items = list(
//		/obj/item/reagent_container/food/snacks/meat,
//		/obj/item/reagent_container/food/snacks/grown/icepepper,
//		/obj/item/reagent_container/food/snacks/grown/tomato,
//	)
//	result = /obj/item/reagent_container/food/snacks/coldchili

/datum/recipe/enchiladas
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/cutlet,
		/obj/item/reagent_container/food/snacks/grown/chili,
		/obj/item/reagent_container/food/snacks/grown/corn,
	)

	result = /obj/item/reagent_container/food/snacks/enchiladas

/datum/recipe/monkeysdelight
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/monkeycube,
		/obj/item/reagent_container/food/snacks/grown/banana,
	)
	required_chemicals = list(
		"sodiumchloride" = 1,
		"blackpepper" = 1
	)

	result = /obj/item/reagent_container/food/snacks/monkeysdelight

///datum/recipe/baguette
//	reagents = list("sodiumchloride" = 1, "blackpepper" = 1)
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//	)
//	result = /obj/item/reagent_container/food/snacks/baguette

/datum/recipe/fishandchips
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/fries,
		/obj/item/reagent_container/food/snacks/carpmeat,
	)

	result = /obj/item/reagent_container/food/snacks/fishandchips

///datum/recipe/sandwich
//	items = list(
//		/obj/item/reagent_container/food/snacks/meatsteak,
//		/obj/item/reagent_container/food/snacks/breadslice,
//		/obj/item/reagent_container/food/snacks/breadslice,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/sandwich

///datum/recipe/toastedsandwich
//	items = list(
//		/obj/item/reagent_container/food/snacks/sandwich,
//	)
//	result = /obj/item/reagent_container/food/snacks/toastedsandwich

///datum/recipe/grilledcheese
//	items = list(
//		/obj/item/reagent_container/food/snacks/breadslice,
//		/obj/item/reagent_container/food/snacks/breadslice,
//		/obj/item/reagent_container/food/snacks/cheesewedge,
//	)
//	result = /obj/item/reagent_container/food/snacks/grilledcheese

///datum/recipe/stew
//	reagents = list("water" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/grown/tomato,
//		/obj/item/reagent_container/food/snacks/meat,
//		/obj/item/reagent_container/food/snacks/grown/potato,
//		/obj/item/reagent_container/food/snacks/grown/carrot,
//		/obj/item/reagent_container/food/snacks/grown/eggplant,
//		/obj/item/reagent_container/food/snacks/grown/mushroom,
//	)
//	result = /obj/item/reagent_container/food/snacks/stew

///datum/recipe/jelliedtoast
//	reagents = list("cherryjelly" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/breadslice,
//	)
//	result = /obj/item/reagent_container/food/snacks/jelliedtoast/cherry

///datum/recipe/stewedsoymeat
//	items = list(
//		/obj/item/reagent_container/food/snacks/soydope,
//		/obj/item/reagent_container/food/snacks/grown/carrot,
//		/obj/item/reagent_container/food/snacks/grown/tomato,
//	)
//	result = /obj/item/reagent_container/food/snacks/stewedsoymeat

/*/datum/recipe/spagetti We have the processor now
	items = list(
		/obj/item/reagent_container/food/snacks/doughslice,
	)
	result= /obj/item/reagent_container/food/snacks/spagetti*/

/datum/recipe/boiledrice
	required_chemicals = list(
		"water" = 5,
		"rice" = 10
	)

	result = /obj/item/reagent_container/food/snacks/boiledrice

/datum/recipe/ricepudding
	required_chemicals = list(
		"milk" = 5,
		"rice" = 10
	)

	result = /obj/item/reagent_container/food/snacks/ricepudding

///datum/recipe/poppypretzel
//	items = list(
//		/obj/item/seeds/poppyseed,
//		/obj/item/reagent_container/food/snacks/dough,
//	)
//	result = /obj/item/reagent_container/food/snacks/poppypretzel

/datum/recipe/candiedapple
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/grown/apple,
	)
	required_chemicals = list(
		"water" = 5,
		"sugar" = 5
	)

	result = /obj/item/reagent_container/food/snacks/candiedapple

///datum/recipe/twobread
//	reagents = list("wine" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/breadslice,
//		/obj/item/reagent_container/food/snacks/breadslice,
//	)
//	result = /obj/item/reagent_container/food/snacks/twobread

///datum/recipe/cherrysandwich
//	reagents = list("cherryjelly" = 5)
//	items = list(
//		/obj/item/reagent_container/food/snacks/breadslice,
//		/obj/item/reagent_container/food/snacks/breadslice,
//	)
//	result = /obj/item/reagent_container/food/snacks/jellysandwich/cherry

/datum/recipe/sausage
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/meatball,
		/obj/item/reagent_container/food/snacks/cutlet,
	)

	result = /obj/item/reagent_container/food/snacks/sausage

/datum/recipe/fishfingers
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/carpmeat,
	)

	result = /obj/item/reagent_container/food/snacks/fishfingers

/datum/recipe/plumphelmetbiscuit
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/grown/mushroom/plumphelmet,
	)
	required_chemicals = list(
		"water" = 5
	)

	result = /obj/item/reagent_container/food/snacks/plumphelmetbiscuit

/datum/recipe/chawanmushi
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/grown/mushroom/chanterelle,
	)
	required_chemicals = list(
		"water" = 5,
		"soysauce" = 5
	)

	result = /obj/item/reagent_container/food/snacks/chawanmushi

///datum/recipe/tossedsalad
//	items = list(
//		/obj/item/reagent_container/food/snacks/grown/cabbage,
//		/obj/item/reagent_container/food/snacks/grown/tomato,
//		/obj/item/reagent_container/food/snacks/grown/carrot,
//		/obj/item/reagent_container/food/snacks/grown/apple,
//	)
//	result = /obj/item/reagent_container/food/snacks/tossedsalad

///datum/recipe/aesirsalad
//	items = list(
//		/obj/item/reagent_container/food/snacks/grown/ambrosiadeus,
//		/obj/item/reagent_container/food/snacks/grown/goldapple,
//	)
//	result = /obj/item/reagent_container/food/snacks/aesirsalad

///datum/recipe/validsalad
//	items = list(
//		/obj/item/reagent_container/food/snacks/grown/ambrosiavulgaris,
//		/obj/item/reagent_container/food/snacks/grown/potato,
//		/obj/item/reagent_container/food/snacks/meatball,
//	)
//	result = /obj/item/reagent_container/food/snacks/validsalad
//
///datum/recipe/validsalad/make_food(obj/container as obj)
//	var/obj/item/reagent_container/food/snacks/validsalad/being_cooked = ..(container)
//	being_cooked.reagents.del_reagent("toxin")
//	return being_cooked

/datum/recipe/cracker
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/doughslice,
	)
	required_chemicals = list(
		"sodiumchloride" = 1
	)

	result = /obj/item/reagent_container/food/snacks/cracker

/datum/recipe/stuffing
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/sliceable/bread,
	)
	required_chemicals = list(
		"water" = 5,
		"sodiumchloride" = 1,
		"blackpepper" = 1
	)

	result = /obj/item/reagent_container/food/snacks/stuffing

/datum/recipe/tofurkey
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/tofu,
		/obj/item/reagent_container/food/snacks/stuffing,
	)

	result = /obj/item/reagent_container/food/snacks/tofurkey

///datum/recipe/cheesewheel/mature
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/cheesewheel/immature,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/cheesewheel/mature
//
///datum/recipe/cheesewheel/verymature
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/cheesewheel/mature,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/cheesewheel/verymature
//
///datum/recipe/cheesewheel/extramature
//	reagents = list("sugar" = 5, "milk" = 5, "sodiumchloride" = 1, "leporazine" = 10)
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/cheesewheel/verymature,
//	)
//	result = /obj/item/reagent_container/food/snacks/sliceable/cheesewheel/extramature

//////////////////////////////////////////
// bs12 food port stuff
//////////////////////////////////////////

/datum/recipe/taco
	required_ingredients = list(
		/obj/item/reagent_container/food/snacks/doughslice,
		/obj/item/reagent_container/food/snacks/cutlet,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)

	result = /obj/item/reagent_container/food/snacks/taco

///datum/recipe/bun
//	reagents = list("sodiumchloride" = 1)
//	items = list(
//		/obj/item/reagent_container/food/snacks/dough,
//	)
//	result = /obj/item/reagent_container/food/snacks/bun

///datum/recipe/flatbread
//	items = list(
//		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
//	)
//	result = /obj/item/reagent_container/food/snacks/flatbread

///datum/recipe/meatball
//	items = list(
//		/obj/item/reagent_container/food/snacks/rawmeatball,
//	)
//	result = /obj/item/reagent_container/food/snacks/meatball

///datum/recipe/cutlet
//	items = list(
//		/obj/item/reagent_container/food/snacks/rawcutlet,
//	)
//	result = /obj/item/reagent_container/food/snacks/cutlet

//datum/recipe/fries
//	items = list(
//		/obj/item/reagent_container/food/snacks/rawsticks,
//	)
//	result = /obj/item/reagent_container/food/snacks/fries

/datum/recipe/mint
	required_chemicals = list(
		"sugar" = 5,
		"frostoil" = 5
	)
	result = /obj/item/reagent_container/food/snacks/mint
