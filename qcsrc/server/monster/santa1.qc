// Santa for Rexuiz
//
// model+sounds used are taken from the Arcane Dimensions Xmas Jam 2017:
// https://www.moddb.com/mods/arcane-dimensions/addons/xmas-jam-2017-v2
//
// Santas code is derived from butcher.qc

void() monster_santa1_idle;
void() monster_santa1_guard;
void() monster_santa1_walk;

#define MONSTER_SANTA1_ANIM_WALK '6 6 6'
#define MONSTER_SANTA1_ANIM_RUN '7 5 5'
#define MONSTER_SANTA1_ANIM_IDLE '0 6 6'
#define MONSTER_SANTA1_ANIM_SACK_ATTACK '32 8 16'
#define MONSTER_SANTA1_ANIM_GUN_ATTACK '28 4 4'

#define MONSTER_SANTA1_VIEW_OFFSET '0 0 35'
#define MONSTER_SANTA1_SIZE_MIN '-20 -20 -25'
#define MONSTER_SANTA1_SIZE_MAX '20 20 45'

#define MONSTER_SANTA1_NETNAME "Santa"
#define MONSTER_SANTA1_MDL "models/ctest1/santa2.mdl"
#define MONSTER_SANTA1_SNOWBALL_MDL "models/ctest1/proj_snowball.mdl"
#define MONSTER_SANTA1_SOUND_DETECT "sound/ctest1/santa/hohoho.wav"
#define MONSTER_SANTA1_SOUND_PAIN "sound/ctest1/santa/pain1.wav"
#define MONSTER_SANTA1_SOUND_SACK_HIT "sound/ctest1/santa/sack_hit.wav"
#define MONSTER_SANTA1_SOUND_SACK_SWING "sound/ctest1/santa/sack_swing.wav"
#define MONSTER_SANTA1_SOUND_ROCKET "weapons/rocket_fire.wav"
#define MONSTER_SANTA1_DLC "santa2"

// debug:
//#define MONSTER_SANTA1_RUN_SPEED 200
#define MONSTER_SANTA1_RUN_SPEED 300
#define MONSTER_SANTA1_RUN_DIST  300
#define MONSTER_SANTA1_WALK_SPEED 100

// Santa-Gun: offset 
// Gun barrels left/right (_l/_r) from Santas perspective
#define MONSTER_SANTA1_GUN_OFFSET_FW 28
// for z axis offset
#define MONSTER_SANTA1_GUN_V_OFFSET_L '0 0 18'
#define MONSTER_SANTA1_GUN_V_OFFSET_R '0 0 24'
// snowball gun shot -> move orign to the right
#define MONSTER_SANTA1_GUN_R_OFFSET_L 18
#define MONSTER_SANTA1_GUN_R_OFFSET_R 26
#define MONSTER_SANTA1_SNOWBALL_VELOCITY 400

// mele animation looks better when started from a distance:
#define MONSTER_SANTA1_MELE_DISTANCE 200

void() monster_santa1_hunt {
	anim_update(self);
	self.nextthink = time;
	if (monster_check_target(monster_santa1_walk, monster_santa1_guard))
		return;

	vector	v;
	vector	v_offset;
	float	r_offset;

	vector _shotdir;
	float	dofire;
	dofire	= FALSE;

	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	if (dofire) {
		if (vlen(monster_look_to_end - self.origin) < MONSTER_SANTA1_MELE_DISTANCE) {
			v = vectoangles(monster_look_to_end - self.origin);
			self.angles_y = v_y;
			makevectors(self.angles);
			self.bulletcounter = time + 1;
			trace_box(self.origin, '-8 -8 -8', '8 8 8', self.origin + v_forward * 80, TRACE_MOVE_NORMAL, self);
			move_beak_simple(2000 * frametime);
			anim_set(self, MONSTER_SANTA1_ANIM_SACK_ATTACK, TRUE, TRUE, FALSE);
			anim_update(self);
			sound(self, CHAN_WEAPON, MONSTER_SANTA1_SOUND_SACK_SWING, VOL_BASE, ATTN_NORM);
			self.nextthink = time + 0.25;
			if (trace_ent) {
				sound(self, CHAN_WEAPON, MONSTER_SANTA1_SOUND_SACK_HIT, VOL_BASE, ATTN_NORM);
				damage(trace_ent, self, self, self.dmg_edge, WEAPON_MELEE, trace_endpos, v_forward);
				self.lastshot_time = time;
			}
			self.attack_finished_single = time + 0.5 + random();
			self.bulletcounter = time + 1;
		} else {
			if (random() < 0.03) {
				sound(self, CHAN_WEAPON, MONSTER_SANTA1_SOUND_ROCKET, VOL_BASE, ATTN_NORM);
				// fire rocket -> stop moving
				self.velocity = (self.origin * 0);
				vector v = monster_move_walk(0, 0, 0);

				//move_beak_simple(2000 * frametime);
				anim_update(self);
				anim_set(self, MONSTER_SANTA1_ANIM_GUN_ATTACK, TRUE, TRUE, FALSE);

				// random shot left/right barrel:
				if (random() < 0.5) {
					// RIGHT gun barrel (...from santas 1st person perspective)
					v_offset = MONSTER_SANTA1_GUN_V_OFFSET_R;
					r_offset = MONSTER_SANTA1_GUN_R_OFFSET_R;
				} else {
					// LEFT gun barrel
					v_offset = MONSTER_SANTA1_GUN_V_OFFSET_L;
					r_offset = MONSTER_SANTA1_GUN_R_OFFSET_L;
				}

				v = vectoangles(monster_look_to_end - self.origin - v_offset);
				self.angles_y = v_y;
				makevectors(self.angles);
				vector _shotorg = self.origin + v_forward * MONSTER_SANTA1_GUN_OFFSET_FW + v_right * r_offset  + v_offset;
				vector _shotdir = monster_look_to_end - _shotorg;

				entity missile = monster_projectile(TRUE, PROJECTILE_SNOWBALL, TRUE, self);
				projectile_setup(missile, _shotorg, EFFECT_IMPACT_ROCKET, WEAPON_ROCKET_LAUNCHER, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
				missile.nextthink = time + 5;
				missile.think = projectile_think2use;
				missile.use = projectile_explode;
				missile.touch = projectile_touch_explode;
				missile.velocity = normalize(_shotdir) * MONSTER_SANTA1_SNOWBALL_VELOCITY;
				weapon_setup_projectile_velocity(missile);

				// bit of a light effect, when Santa fires Snowballs
				pointparticles(particleeffectnum("shotgun_muzzleflash"), _shotorg, _shotdir * 1000, 1);

				// timing?
				self.attack_finished_single = time + 1 + random();
				self.bulletcounter = time + 1;
				self.lastshot_time = time;
				self.nextthink = time + 1;

			}
		}
	}
	if (time > self.bulletcounter) {
		v = monster_move_walk(MONSTER_SANTA1_RUN_SPEED, 5, MONSTER_SANTA1_RUN_DIST);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
		// required to keep melee animation active?
		if (vlen(monster_look_to_end - self.origin) > MONSTER_SANTA1_MELE_DISTANCE) {
			anim_update(self);
			anim_set(self, MONSTER_SANTA1_ANIM_RUN, TRUE, TRUE, FALSE);
		}
	}
}

void() monster_santa1_idle {
	anim_update(self);
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 1, 3)) {
		return;
	}
	move_beak_simple(100 * frametime);
	anim_update(self);
	anim_set(self, MONSTER_SANTA1_ANIM_IDLE, TRUE, TRUE, FALSE);
}

void() monster_santa1_guard {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	monster_santa1_idle();
}

void() monster_santa1_walk {
	anim_update(self);
	self.nextthink = time;
	//
	//entity monster_look_for_player(float distance, float heardistance, float fov_factor, float attack_delay, float attack_delay_jitter)
	if (monster_look_for_player(1500, 500, 0, 0, 0)) {
		return;
	}
	if (monster_walk_finished(monster_santa1_idle, 100))
		return;

	anim_update(self);
	anim_set(self, MONSTER_SANTA1_ANIM_WALK, TRUE, TRUE, FALSE);
	vector v = monster_move_walk(MONSTER_SANTA1_WALK_SPEED, 5, 0);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
}

void() monster_santa1_spawn {
	monster_prepare(monster_santa1_hunt, monster_santa1_walk, monster_santa1_idle);
	setmodel(self, MONSTER_SANTA1_MDL);
	self.movetype = MOVETYPE_WALK;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = MONSTER_SANTA1_NETNAME;
	self.view_ofs = MONSTER_SANTA1_VIEW_OFFSET;
}

void() santa1_init {
	precache_model(MONSTER_SANTA1_MDL);
	precache_model(MONSTER_SANTA1_SNOWBALL_MDL);
	precache_sound(MONSTER_SANTA1_SOUND_DETECT);
	precache_sound(MONSTER_SANTA1_SOUND_PAIN);
	precache_sound(MONSTER_SANTA1_SOUND_SACK_HIT);
	precache_sound(MONSTER_SANTA1_SOUND_SACK_SWING);
	precache_sound(MONSTER_SANTA1_SOUND_ROCKET);
	dlc_require(MONSTER_SANTA1_DLC);
}

void() spawnfunc_monster_santa1_spawn {
	setsize(self, MONSTER_SANTA1_SIZE_MIN, MONSTER_SANTA1_SIZE_MAX);
	monster_init(santa1_init);
	self.noise1 = MONSTER_SANTA1_SOUND_DETECT;
	self.noise3 = MONSTER_SANTA1_SOUND_PAIN;
	monster_prepare_spawn(monster_santa1_spawn, spawnfunc_monster_santa1_spawn);
}
