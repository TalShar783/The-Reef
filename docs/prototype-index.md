# Factorio 2.x Prototype Index

Generated from prototype-api.json (api_version 6, game 2.1.8).
Entries marked **[NO DESC]** have blank descriptions in the API — fill these in manually.

| Prototype class | typename | Description |
|---|---|---|
| AccumulatorPrototype | accumulator | Entity with energy source with specialised animation for charging/discharging |
| AchievementPrototype | achievement | This prototype definition is used for the in-game achievements |
| AchievementPrototypeWithCondition *(abstract)* | *(abstract)* | **[NO DESC]** |
| ActiveDefenseEquipmentPrototype | active-defense-equipment | Used by discharge defense and personal laser defense |
| ActiveTriggerPrototype *(abstract)* | *(abstract)* | The abstract base of all active trigger prototypes |
| AgriculturalTowerPrototype | agricultural-tower | A stationary machine that plants trees and then harvests them into its internal inventory once they are mature. |
| AirbornePollutantPrototype | airborne-pollutant | A type of pollution that can spread throughout the chunks of a map |
| AmbientSound | ambient-sound | This prototype is used to make sound while playing the game |
| AmmoCategory | ammo-category | An ammo category |
| AmmoItemPrototype | ammo | Ammo used for a gun |
| AmmoTurretPrototype | ammo-turret | A turret that consumes ammo items |
| AnimationPrototype | animation | Specifies an animation that can be used with LuaRendering::draw_animation at runtime |
| ArithmeticCombinatorPrototype | arithmetic-combinator | An arithmetic combinator |
| ArmorPrototype | armor | Armor to wear on your in-game character for defense and buffs |
| ArrowPrototype | arrow | The arrows used for example in the campaign, they are literally just arrows |
| ArtilleryFlarePrototype | artillery-flare | The entity spawned by the artillery targeting remote |
| ArtilleryProjectilePrototype | artillery-projectile | The projectile shot by artillery |
| ArtilleryTurretPrototype | artillery-turret | An artillery turret |
| ArtilleryWagonPrototype | artillery-wagon | An artillery wagon |
| AssemblingMachinePrototype | assembling-machine | An assembling machine - like the assembling machines 1/2/3 in the game, but you can use your own recipe categories |
| AsteroidChunkPrototype | asteroid-chunk | A healthless entity that floats around. |
| AsteroidCollectorPrototype | asteroid-collector | A space-platform machine that grabs asteroid chunks in a range in front of it. |
| AsteroidPrototype | asteroid | An entity that floats around and has health, and damages entities when it touches them by damaging itself. |
| AutoplaceControl | autoplace-control | A setting in the map creation GUI |
| BatteryEquipmentPrototype | battery-equipment | Used by personal battery |
| BeaconPrototype | beacon | Entity with the ability to transfer module effects to its neighboring entities |
| BeamPrototype | beam | Used as a laser beam |
| BeltImmunityEquipmentPrototype | belt-immunity-equipment | Used by belt immunity equipment |
| BlueprintBookPrototype | blueprint-book | A blueprint book |
| BlueprintItemPrototype | blueprint | A blueprint |
| BoilerPrototype | boiler | A boiler |
| BuildEntityAchievementPrototype | build-entity-achievement | This prototype is used for receiving an achievement when the player builds an entity |
| BurnerGeneratorPrototype | burner-generator | An entity that produces power from a burner energy source |
| BurnerUsagePrototype | burner-usage | Set of data affecting tooltips, looks of gui slots etc when burner is not supposed to be burning items but eating them |
| CapsulePrototype | capsule | A capsule, for example a combat robot capsule or the raw fish |
| CaptureRobotPrototype | capture-robot | A special type of ammo fired from the rocket launcher that turns a biter spawner into a captive biter spawner. |
| CargoBayPrototype | cargo-bay | Interconnecting objects placed on a 2x2 grid that create a chain of reference to a cargo landing pad or platform hub as well as increasing the pad or hub's item capacity. |
| CargoLandingPadPrototype | cargo-landing-pad | Similar to the Space Platform Hub, but exclusive to landable surfaces and does not have any of the space platform controls. Connects to cargo bays to increase capacity. |
| CargoPodPrototype | cargo-pod | A small visual rocket that is launched from Space Platforms when they drop or transfer items. Has an inventory, knows the container (Cargo Bay) that spawned it, and has a trigger when it impacts. |
| CargoWagonPrototype | cargo-wagon | A cargo wagon |
| CarPrototype | car | Entity with specialized properties for acceleration, braking, and turning |
| ChainActiveTriggerPrototype | chain-active-trigger | Jumps between targets and applies a Trigger to them |
| ChangedSurfaceAchievementPrototype | change-surface-achievement | This prototype is used for receiving an achievement when the player changes to a surface |
| CharacterCorpsePrototype | character-corpse | The corpse of a CharacterPrototype |
| CharacterPrototype | character | Entity that you move around on the screen during the campaign and freeplay |
| CliffPrototype | cliff | A cliff |
| CollisionLayerPrototype | collision-layer | A collision layer |
| CombatRobotCountAchievementPrototype | combat-robot-count-achievement | This prototype is used for receiving an achievement when the player has a certain robot follower count |
| CombatRobotPrototype | combat-robot | A combat robot |
| CombinatorPrototype *(abstract)* | *(abstract)* | Abstract base type for decider and arithmetic combinators |
| CompleteObjectiveAchievementPrototype | complete-objective-achievement | **[NO DESC]** |
| ConstantCombinatorPrototype | constant-combinator | A constant combinator |
| ConstructionRobotPrototype | construction-robot | A construction robot |
| ConstructWithRobotsAchievementPrototype | construct-with-robots-achievement | This prototype is used for receiving an achievement when the player constructs enough entities with construction robots |
| ContainerPrototype | container | A generic container, such as a chest |
| CopyPasteToolPrototype | copy-paste-tool | A copy-paste or cut-paste tool |
| CorpsePrototype | corpse | Used for corpses, for example the remnants when destroying buildings |
| CraftingMachinePrototype *(abstract)* | *(abstract)* | The abstract basis of the assembling machines and furnaces |
| CreatePlatformAchievementPrototype | create-platform-achievement | This prototype is used for receiving an achievement when the player creates a space platform |
| CurvedRailAPrototype | curved-rail-a | A curved-A rail |
| CurvedRailBPrototype | curved-rail-b | A curved-B rail |
| CustomEventPrototype | custom-event | Custom events share the same namespace as custom inputs and built-in events for subscribing to and raising them |
| CustomInputPrototype | custom-input | Used for custom keyboard shortcuts/key bindings in mods |
| DamageType | damage-type | A damage type |
| DeciderCombinatorPrototype | decider-combinator | A decider combinator |
| DeconstructibleTileProxyPrototype | deconstructible-tile-proxy | Entity used to signify that the tile below it should be deconstructed |
| DeconstructionItemPrototype | deconstruction-item | A deconstruction planner |
| DeconstructWithRobotsAchievementPrototype | deconstruct-with-robots-achievement | This prototype is used for receiving an achievement when the player deconstructs enough entities with construction robots |
| DecorativePrototype | optimized-decorative | Simple decorative purpose objects on the map, they have no health and some of them are removed when the player builds over |
| DelayedActiveTriggerPrototype | delayed-active-trigger | Delays the delivery of triggered effect by some number of ticks |
| DeliverByRobotsAchievementPrototype | deliver-by-robots-achievement | This prototype is used for receiving an achievement, when the player requests and receives enough items using logistic robots |
| DeliverCategory | deliver-category | Only has a name and a type. Seems to be intended to transfer something from one thing to another. |
| DeliverImpactCombination | deliver-impact-combination | Can trigger an effect on impact. |
| DepleteResourceAchievementPrototype | deplete-resource-achievement | This prototype is used for receiving an achievement when a resource entity is depleted |
| DestroyCliffAchievementPrototype | destroy-cliff-achievement | **[NO DESC]** |
| DisplayPanelPrototype | display-panel | Entity that display a signal icon and some text, either configured directly in the entity or through the circuit network |
| DontBuildEntityAchievementPrototype | dont-build-entity-achievement | This prototype is used for receiving an achievement when the player finishes the game without building a specific entity |
| DontCraftManuallyAchievementPrototype | dont-craft-manually-achievement | This prototype is used for receiving an achievement when the player finishes the game without crafting more than a set amount |
| DontKillManuallyAchievementPrototype | dont-kill-manually-achievement | This prototype is used for receiving an achievement when the player kill first entity using artillery |
| DontResearchBeforeResearchingAchievementPrototype | dont-research-before-researching-achievement | This prototype is used for receiving an achievement when the player researches with a specific science pack before unlocking another |
| DontUseEntityInEnergyProductionAchievementPrototype | dont-use-entity-in-energy-production-achievement | This prototype is used for receiving an achievement when the player finishes the game without receiving energy from a specific energy source |
| EditorControllerPrototype | editor-controller | Properties of the editor controller |
| ElectricEnergyInterfaceEquipmentPrototype | electric-energy-interface-equipment | Provides or consumes power in equipment grids |
| ElectricEnergyInterfacePrototype | electric-energy-interface | Entity with electric energy source with that can have some of its values changed runtime |
| ElectricPolePrototype | electric-pole | An electric pole - part of the electric system |
| ElectricTurretPrototype | electric-turret | A turret that uses electricity as ammunition |
| ElevatedCurvedRailAPrototype | elevated-curved-rail-a | An elevated curved-A rail |
| ElevatedCurvedRailBPrototype | elevated-curved-rail-b | An elevated curved-B rail |
| ElevatedHalfDiagonalRailPrototype | elevated-half-diagonal-rail | An elevated half diagonal rail |
| ElevatedStraightRailPrototype | elevated-straight-rail | An elevated straight rail |
| EnemySpawnerPrototype | unit-spawner | Can spawn entities |
| EnergyShieldEquipmentPrototype | energy-shield-equipment | Used by energy shield |
| EntityGhostPrototype | entity-ghost | The entity used for ghosts of entities |
| EntityPrototype *(abstract)* | *(abstract)* | Abstract base of all entities in the game |
| EntityWithHealthPrototype *(abstract)* | *(abstract)* | Abstract base of all entities with health in the game |
| EntityWithOwnerPrototype *(abstract)* | *(abstract)* | Abstract base of all entities with a force in the game |
| EquipArmorAchievementPrototype | equip-armor-achievement | This prototype is used for receiving an achievement when the player equips armor |
| EquipmentCategory | equipment-category | Defines a category to be available to equipment and equipment grids |
| EquipmentGhostPrototype | equipment-ghost | The equipment used for ghosts of equipment |
| EquipmentGridPrototype | equipment-grid | The prototype of an equipment grid, for example the one used in a power armor |
| EquipmentPrototype *(abstract)* | *(abstract)* | Abstract base of all equipment modules |
| ExplosionPrototype | explosion | Used to play an animation and a sound |
| FireFlamePrototype | fire | A fire |
| FishPrototype | fish | Entity that spawns in water tiles, which can be mined |
| FluidPrototype | fluid | A fluid |
| FluidStreamPrototype | stream | Used for example for the handheld flamethrower |
| FluidTurretPrototype | fluid-turret | A turret that uses fluid as ammunition |
| FluidWagonPrototype | fluid-wagon | A fluid wagon |
| FlyingRobotPrototype *(abstract)* | *(abstract)* | Abstract base for construction/logistics and combat robots |
| FontPrototype | font | Fonts are used in all GUIs in the game |
| FuelCategory | fuel-category | Each item which has a fuel_value must have a fuel category |
| FurnacePrototype | furnace | A furnace |
| FusionGeneratorPrototype | fusion-generator | Consumes a fluid to generate electricity and create another fluid |
| FusionReactorPrototype | fusion-reactor | Fusion reactor |
| GatePrototype | gate | A gate |
| GeneratorEquipmentPrototype | generator-equipment | Used by portable fusion reactor |
| GeneratorPrototype | generator | An entity that produces power from fluids, for example a steam engine |
| GodControllerPrototype | god-controller | Properties of the god controller |
| GroupAttackAchievementPrototype | group-attack-achievement | This prototype is used for receiving an achievement when the player gets attacked due to pollution |
| GuiStyle | gui-style | The available GUI styles |
| GunPrototype | gun | A gun |
| HalfDiagonalRailPrototype | half-diagonal-rail | A half diagonal rail |
| HeatInterfacePrototype | heat-interface | This entity produces or consumes heat |
| HeatPipePrototype | heat-pipe | A heat pipe |
| HighlightBoxEntityPrototype | highlight-box | Used to attach graphics for cursor boxes to entities during runtime |
| ImpactCategory | impact-category | **[NO DESC]** |
| InfinityCargoWagonPrototype | infinity-cargo-wagon | A cargo wagon that can spawn or void items at will |
| InfinityContainerPrototype | infinity-container | A generic container, such as a chest, that can spawn or void items and interact with the logistics network |
| InfinityPipePrototype | infinity-pipe | This entity produces or consumes fluids |
| InserterPrototype | inserter | An inserter |
| InventoryBonusEquipmentPrototype | inventory-bonus-equipment | An item that can be placed into an equipment grid. |
| ItemEntityPrototype | item-entity | The entity used for items on the ground |
| ItemGroup | item-group | An item group |
| ItemPrototype | item | Possible configuration for all items |
| ItemRequestProxyPrototype | item-request-proxy | Entity used to signify that an entity is requesting items, for example modules for an assembling machine after it was blueprinted with modules inside |
| ItemSubGroup | item-subgroup | An item subgroup |
| ItemWithEntityDataPrototype | item-with-entity-data | ItemWithEntityData saves data associated with the entity that it represents, for example the content of the equipment grid of a car |
| ItemWithInventoryPrototype | item-with-inventory | The inventory allows setting player defined filters similar to cargo wagon inventories |
| ItemWithLabelPrototype | item-with-label | Like a normal item but with the ability to have a colored label |
| ItemWithTagsPrototype | item-with-tags | Item type that can store any basic arbitrary Lua data, see LuaItemStack::tags |
| KillAchievementPrototype | kill-achievement | This prototype is used for receiving an achievement when the player destroys a certain amount of an entity, with a specific damage type |
| LabPrototype | lab | A lab |
| LampPrototype | lamp | A lamp to provide light, using energy |
| LandMinePrototype | land-mine | A land mine |
| LaneSplitterPrototype | lane-splitter | A 1x1 machine meant to be placed inline with belts. Can split lanes but not push/pull into non-belt entities. Hidden in base game. |
| LegacyCurvedRailPrototype | legacy-curved-rail | A legacy curved rail |
| LegacyStraightRailPrototype | legacy-straight-rail | A legacy straight rail |
| LightningAttractorPrototype | lightning-attractor | Absorbs lightning and optionally converts it into electricity |
| LightningPrototype | lightning | Lightning randomly hits entities on planets with lightning_properties |
| LinkedBeltPrototype | linked-belt | A belt that can be connected to a belt anywhere else, including on a different surface |
| LinkedContainerPrototype | linked-container | A container that shares its inventory with containers with the same link_id, which can be set via the GUI |
| Loader1x1Prototype | loader-1x1 | Continuously loads and unloads machines, as an alternative to inserters |
| Loader1x2Prototype | loader | Continuously loads and unloads machines, as an alternative to inserters |
| LoaderPrototype *(abstract)* | *(abstract)* | Continuously loads and unloads machines, as an alternative to inserters |
| LocomotivePrototype | locomotive | A locomotive |
| LogisticContainerPrototype | logistic-container | A generic container, such as a chest, that interacts with the logistics network |
| LogisticRobotPrototype | logistic-robot | A logistic robot |
| MapGenPresets | map-gen-presets | The available map gen presets |
| MapSettings | map-settings | The default map settings |
| MarketPrototype | market | Offers can be added to a market and they are shown when opening the entity |
| MiningDrillPrototype | mining-drill | A mining drill for automatically extracting resources from resource entities |
| ModData | mod-data | Block of arbitrary data set by mods in prototype stage |
| ModuleCategory | module-category | A module category |
| ModulePrototype | module | A module |
| ModuleTransferAchievementPrototype | module-transfer-achievement | This prototype is used for receiving an achievement when the player moves a module with the cursor |
| MouseCursor | mouse-cursor | Used by SelectionToolPrototype::mouse_cursor |
| MovementBonusEquipmentPrototype | movement-bonus-equipment | Used by exoskeleton |
| NamedNoiseExpression | noise-expression | A NoiseExpression with a name |
| NamedNoiseFunction | noise-function | Named noise functions are defined in the same way as NamedNoiseExpression except that they also have parameters |
| NightVisionEquipmentPrototype | night-vision-equipment | Used by nightvision |
| OffshorePumpPrototype | offshore-pump | An offshore pump |
| ParticlePrototype | optimized-particle | An entity with a limited lifetime that can use trigger effects |
| ParticleSourcePrototype | particle-source | Creates particles |
| PipePrototype | pipe | An entity to transport fluids over a distance and between machines |
| PipeToGroundPrototype | pipe-to-ground | A pipe to ground |
| PlaceEquipmentAchievementPrototype | place-equipment-achievement | **[NO DESC]** |
| PlanetPrototype | planet | Includes properties pertaining to where on the map it appears, what kind of pollution it uses, ambient sounds, effects on the players, whether machines freeze, and map generation settings. |
| PlantPrototype | plant | **[NO DESC]** |
| PlayerDamagedAchievementPrototype | player-damaged-achievement | This prototype is used for receiving an achievement when the player receives damage |
| PlayerPortPrototype | player-port | Deprecated in 2 |
| PowerSwitchPrototype | power-switch | A power switch |
| ProcessionLayerInheritanceGroup | procession-layer-inheritance-group | Helps ProcessionLayers pass properties between subsequent transitions if they belong to the same group |
| ProcessionPrototype | procession | Describes the duration and visuals of a departure, arrival or an intermezzo while traveling between surfaces |
| ProduceAchievementPrototype | produce-achievement | This prototype is used for receiving an achievement when the player produces more than the specified amount of items |
| ProducePerHourAchievementPrototype | produce-per-hour-achievement | This prototype is used for receiving an achievement when the player crafts a specified item a certain amount, in an hour |
| ProgrammableSpeakerPrototype | programmable-speaker | A programmable speaker |
| ProjectilePrototype | projectile | Entity with limited lifetime that can hit other entities and has triggers when this happens |
| Prototype *(abstract)* | *(abstract)* | **[NO DESC]** |
| PrototypeBase *(abstract)* | *(abstract)* | The abstract base for prototypes |
| ProxyContainerPrototype | proxy-container | A container that must be set to point at other entity and inventory index so it can forward all inventory interactions to the other entity |
| PumpPrototype | pump | The pump is used to transfer fluids between tanks, fluid wagons and pipes |
| QualityPrototype | quality | One quality step |
| RadarPrototype | radar | A radar |
| RailChainSignalPrototype | rail-chain-signal | A rail chain signal |
| RailPlannerPrototype | rail-planner | A rail planner |
| RailPrototype *(abstract)* | *(abstract)* | The abstract base of all rail prototypes |
| RailRampPrototype | rail-ramp | A rail ramp |
| RailRemnantsPrototype | rail-remnants | Used for rail corpses |
| RailSignalBasePrototype *(abstract)* | *(abstract)* | The abstract base entity for both rail signals |
| RailSignalPrototype | rail-signal | A rail signal |
| RailSupportPrototype | rail-support | **[NO DESC]** |
| ReactorPrototype | reactor | A reactor |
| RecipeCategory | recipe-category | A recipe category |
| RecipePrototype | recipe | A recipe |
| RemoteControllerPrototype | remote-controller | Properties of the remote controller |
| RepairToolPrototype | repair-tool | A repair pack |
| ResearchAchievementPrototype | research-achievement | This prototype is used for receiving an achievement when the player completes a specific research |
| ResearchWithSciencePackAchievementPrototype | research-with-science-pack-achievement | **[NO DESC]** |
| ResourceCategory | resource-category | A resource category |
| ResourceEntityPrototype | resource | A mineable/gatherable entity |
| RoboportEquipmentPrototype | roboport-equipment | Used by personal roboport |
| RoboportPrototype | roboport | A roboport |
| RobotWithLogisticInterfacePrototype *(abstract)* | *(abstract)* | The common properties of logistic and construction robots represented by an abstract prototype |
| RocketSiloPrototype | rocket-silo | A rocket silo |
| RocketSiloRocketPrototype | rocket-silo-rocket | The rocket inside the rocket silo |
| RocketSiloRocketShadowPrototype | rocket-silo-rocket-shadow | The shadow of the rocket inside the rocket silo |
| RollingStockPrototype *(abstract)* | *(abstract)* | The abstract base of all rolling stock |
| SegmentedUnitPrototype | segmented-unit | Entity composed of multiple segment entities that trail behind the head |
| SegmentPrototype | segment | Entity representing an individual segment in a SegmentedUnitPrototype |
| SelectionToolPrototype | selection-tool | Used in the base game as a base for the blueprint item and the deconstruction item |
| SelectorCombinatorPrototype | selector-combinator | **[NO DESC]** |
| ShootAchievementPrototype | shoot-achievement | This prototype is used for receiving an achievement when the player shoots certain ammo |
| ShortcutPrototype | shortcut | Definition for a shortcut button in the shortcut bar |
| SimpleEntityPrototype | simple-entity | An extremely basic entity with no special functionality |
| SimpleEntityWithForcePrototype | simple-entity-with-force | By default, this entity will be a priority target for units/turrets, who will choose to attack it even if it does not block their path |
| SimpleEntityWithOwnerPrototype | simple-entity-with-owner | Has a force, but unlike SimpleEntityWithForcePrototype it is only attacked if the biters get stuck on it (or if EntityWithOwnerPrototype::is_military_target set to true to make the two entity types equivalent) |
| SmokePrototype *(abstract)* | *(abstract)* | Abstract entity that has an animation |
| SmokeWithTriggerPrototype | smoke-with-trigger | An entity with animation and a trigger |
| SolarPanelEquipmentPrototype | solar-panel-equipment | A portable solar panel |
| SolarPanelPrototype | solar-panel | A solar panel |
| SoundPrototype | sound | Specifies a sound that can be used with SoundPath at runtime |
| SpaceConnectionDistanceTraveledAchievementPrototype | space-connection-distance-traveled-achievement | **[NO DESC]** |
| SpaceConnectionPrototype | space-connection | The route between one body and another on the space map. Traveled by Space Platforms. Has asteroid spawn settings and length |
| SpaceLocationPrototype | space-location | A space location, such as a planet or the solar system edge. Gravity_pull is defined here. |
| SpacePlatformHubPrototype | space-platform-hub | **[NO DESC]** |
| SpacePlatformStarterPackPrototype | space-platform-starter-pack | **[NO DESC]** |
| SpectatorControllerPrototype | spectator-controller | Properties of the spectator controller |
| SpeechBubblePrototype | speech-bubble | A speech bubble |
| SpiderLegPrototype | spider-leg | Used by SpiderLegSpecification for SpiderVehiclePrototype, also known as spidertron |
| SpidertronRemotePrototype | spidertron-remote | The spidertron remote |
| SpiderUnitPrototype | spider-unit | **[NO DESC]** |
| SpiderVehiclePrototype | spider-vehicle | A spidertron |
| SplitterPrototype | splitter | A splitter |
| SpritePrototype | sprite | Specifies an image that can be used with SpritePath at runtime |
| StickerPrototype | sticker | Entity that sticks to another entity, and damages/slows it |
| StorageTankPrototype | storage-tank | A storage tank |
| StraightRailPrototype | straight-rail | A straight rail |
| SurfacePropertyPrototype | surface-property | A property with units and and a default value that can be checked against for planet-specific recipes and structures. Native ones include air pressure, gravity, temperature, and electric field strength. |
| SurfacePrototype | surface | Owned by landable surfaces. Contains a list of surface properties. |
| TechnologyPrototype | technology | A technology |
| TemporaryContainerPrototype | temporary-container | A container that can automatically destroy itself when it is emptied or after it has existed for a certain time |
| ThrusterPrototype | thruster | Consumes two fluids as fuel to produce thrust for a space platform |
| TileEffectDefinition | tile-effect | Used to define the parameters for tile shaders |
| TileGhostPrototype | tile-ghost | The entity used for tile ghosts |
| TilePrototype | tile | A tile |
| TipsAndTricksItem | tips-and-tricks-item | A tips and tricks entry |
| TipsAndTricksItemCategory | tips-and-tricks-item-category | A TipsAndTricksItem category, used for sorting of tips and tricks entries: Tips and trick entries are sorted first by category and then by their order within that category |
| ToolPrototype | tool | Items with a "durability" |
| TrainPathAchievementPrototype | train-path-achievement | This prototype is used for receiving an achievement when the player has a specified train path length |
| TrainStopPrototype | train-stop | A train stop |
| TransportBeltConnectablePrototype *(abstract)* | *(abstract)* | Abstract class that anything that is a belt or can connect to belts uses |
| TransportBeltPrototype | transport-belt | A transport belt |
| TreePrototype | tree | A tree |
| TriggerTargetType | trigger-target-type | The base game always internally defines a "common" trigger target type |
| TrivialSmokePrototype | trivial-smoke | Smoke, but it's not an entity for optimization purposes |
| TurretPrototype | turret | A turret that needs no extra ammunition |
| TutorialDefinition | tutorial | The definition of the tutorial to be used in the tips and tricks, see TipsAndTricksItem |
| UndergroundBeltPrototype | underground-belt | An underground belt |
| UnitPrototype | unit | Entity that moves around and attacks players, for example biters and spitters |
| UpgradeItemPrototype | upgrade-item | An upgrade planner |
| UseEntityInEnergyProductionAchievementPrototype | use-entity-in-energy-production-achievement | This prototype is used for receiving an achievement when the player produces energy by entity |
| UseItemAchievementPrototype | use-item-achievement | This prototype is used for receiving an achievement when the player uses a capsule |
| UtilityConstants | utility-constants | Constants used by the game that are not specific to certain prototypes |
| UtilitySounds | utility-sounds | Sounds used by the game that are not specific to certain prototypes |
| UtilitySprites | utility-sprites | Sprites used by the game that are not specific to certain prototypes |
| ValvePrototype | valve | A passive device that provides limited control of fluid flow between pipelines |
| VehiclePrototype *(abstract)* | *(abstract)* | Abstract base of all vehicles |
| VirtualSignalPrototype | virtual-signal | A virtual signal |
| WallPrototype | wall | A wall |

---
*Abstract prototypes are base types only — not used directly in data:extend.*
