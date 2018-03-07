class WaveCOM_MissionSet extends X2Mission;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2MissionTemplate> Templates;

    Templates.AddItem(AddMissionTemplate('WaveCOMAvenger'));
	Templates.AddItem(AddMissionTemplate('WaveCOMGuerrillaRecover'));
	Templates.AddItem(AddMissionTemplate('WaveCOMGuerrillaHack'));
	Templates.AddItem(AddMissionTemplate('WaveCOMGuerrillaRelay'));
	Templates.AddItem(AddMissionTemplate('WaveCOMRaid'));
	Templates.AddItem(AddMissionTemplate('WaveCOMRaidTrain'));
	Templates.AddItem(AddMissionTemplate('WaveCOMCityRescue'));
	Templates.AddItem(AddMissionTemplate('WaveCOMCityExtract'));
	Templates.AddItem(AddMissionTemplate('WaveCOMSabotage'));
	Templates.AddItem(AddMissionTemplate('WaveCOMCovertEscape'));
	Templates.AddItem(AddMissionTemplate('WaveCOMRescueOps'));

    return Templates;
}

static function X2MissionTemplate AddMissionTemplate(name missionName)
{
    local X2MissionTemplate Template;
	`CREATE_X2TEMPLATE(class'X2MissionTemplate', Template, missionName);
    return Template;
}