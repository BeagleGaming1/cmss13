/*
---------------------
CIVILIAN
---------------------
*/

/datum/skills/civilian
	name = "Civilian"
	skills = list(
		SKILL_CQC = SKILL_CQC_DEFAULT,
		SKILL_FIREARMS = SKILL_FIREARMS_CIVILIAN,
		SKILL_ENDURANCE = SKILL_ENDURANCE_NONE,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
	)

/datum/skills/civilian/manager
	name = "Weyland-Yutani Manager" // Semi-competent leader with basic knowledge in most things.
	skills = list(
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_OVERWATCH = SKILL_OVERWATCH_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_NOVICE,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_INTEL = SKILL_INTEL_EXPERT,
	)

/datum/skills/civilian/icc_investigation
	name = "ICC CL - Black Market ERT"
	skills = list(
		SKILL_CQC = SKILL_CQC_DEFAULT,
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED, //The ASRS consoles
		SKILL_FIREARMS = SKILL_FIREARMS_CIVILIAN,
		SKILL_POLICE = SKILL_POLICE_SKILLED, //The CMB Tradeband Compliance Device
	)

/datum/skills/civilian/manager/director
	name = "Weyland-Yutani Director"
	skills = list(
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_OVERWATCH = SKILL_OVERWATCH_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_NOVICE,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_FIREMAN = SKILL_FIREMAN_SKILLED,
		SKILL_EXECUTION = SKILL_EXECUTION_TRAINED,
		SKILL_INTEL = SKILL_INTEL_EXPERT,
	)

//civilian that are survivor could be in is own file maybe

/datum/skills/civilian/survivor
	name = "Survivor"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
	)

/datum/skills/civilian/survivor/manager
	name = "Weyland-Yutani Manager"
	skills = list(
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_OVERWATCH = SKILL_OVERWATCH_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_INTEL = SKILL_INTEL_EXPERT,
	)

/datum/skills/civilian/survivor/goon
	name = "Survivor Goon"
	additional_skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_FIREMAN = SKILL_FIREMAN_SKILLED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_FIREARMS = SKILL_FIREARMS_EXPERT,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
	)

/datum/skills/civilian/survivor/pmc
	name = "Survivor PMC"
	additional_skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_FIREMAN = SKILL_FIREMAN_SKILLED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_FIREARMS = SKILL_FIREARMS_EXPERT,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
	)

/datum/skills/civilian/survivor/pmc/medic
	name = "Survivor PMC Medic"
	additional_skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_FIREMAN = SKILL_FIREMAN_SKILLED,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_SURGERY = SKILL_SURGERY_NOVICE,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_FIREARMS = SKILL_FIREARMS_EXPERT,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
	)

/datum/skills/civilian/survivor/pmc/engineer
	name = "Survivor PMC Engineer"
	additional_skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_FIREMAN = SKILL_FIREMAN_SKILLED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_FIREARMS = SKILL_FIREARMS_EXPERT,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
	)

/datum/skills/civilian/survivor/pmc/lead
	name = "Survivor PMC Team Leader"
	additional_skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_FIREMAN = SKILL_FIREMAN_SKILLED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_FIREARMS = SKILL_FIREARMS_EXPERT,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_OVERWATCH = SKILL_OVERWATCH_TRAINED,
		SKILL_JTAC = SKILL_JTAC_TRAINED,
	)

/datum/skills/civilian/survivor/doctor
	name = "Survivor Doctor"
	additional_skills = list(
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
	)

/datum/skills/civilian/survivor/clf
	name = "Survivor CLF"
	additional_skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_NOVICE,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_FIREMAN = SKILL_FIREMAN_SKILLED,
	)

/datum/skills/civilian/survivor/scientist
	name = "Survivor Scientist"
	additional_skills = list(
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
	)

/datum/skills/civilian/survivor/chef
	name = "Survivor Chef"
	additional_skills = list(
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_DOMESTIC = SKILL_DOMESTIC_TRAINED,
	)

/datum/skills/civilian/survivor/miner
	name = "Survivor Miner"
	additional_skills = list(
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_NOVICE,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
	)

/datum/skills/civilian/survivor/trucker
	name = "Survivor Trucker"
	additional_skills = list(
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_VEHICLE = SKILL_VEHICLE_CREWMAN,
	)

/datum/skills/civilian/survivor/engineer
	name = "Survivor Engineer"
	additional_skills = list(
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
	)

/datum/skills/civilian/survivor/chaplain
	name = "Survivor Chaplain"
	additional_skills = list(
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
	)

/datum/skills/civilian/survivor/marshal
	name = "Survivor Marshal"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_FIREMAN = SKILL_FIREMAN_SKILLED,
		SKILL_ENGINEER = SKILL_ENGINEER_NOVICE,
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
	)

/datum/skills/civilian/survivor/prisoner
	name = "Survivor Prisoner"
	additional_skills = list(
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
	)

/datum/skills/civilian/survivor/gangleader
	name = "Survivor Gang Leader"
	additional_skills = list(
		SKILL_FIREMAN = SKILL_FIREMAN_TRAINED,
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
	)

/datum/skills/civilian/fax_responder
	name = "Comms Relay Worker" //Used for fax responder presets, allowing use of appropriate HUDs and basics.
	skills = list(
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_OVERWATCH = SKILL_OVERWATCH_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_NOVICE,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_INTEL = SKILL_INTEL_EXPERT,
	)
