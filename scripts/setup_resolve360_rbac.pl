#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
binmode(STDOUT, ":utf8");

use lib '/opt/otobo/';
use lib '/opt/otobo/Kernel/cpan-lib';
use lib '/opt/otobo/Custom';

use Kernel::System::ObjectManager;

local $Kernel::OM = Kernel::System::ObjectManager->new();

my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');
my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
my $UserObject  = $Kernel::OM->Get('Kernel::System::User');

print "=== 1. CREATING GROUPS (ZONES MÉTIER) ===\n";
my %GroupsToCreate = (
    'agences'      => 'Zone Agences - Front Office',
    'paiements'    => 'Zone Paiements & Monétique - Back Office',
    'credits'      => 'Zone Crédits & Tarification - Back Office',
    'conformite'   => 'Zone Conformité & Fraude',
    'approbateurs' => 'Zone Approbations & Direction',
);

my %GroupIDs;
for my $GroupName (keys %GroupsToCreate) {
    my $GroupID = $GroupObject->GroupLookup( Group => $GroupName );
    if (!$GroupID) {
        $GroupID = $GroupObject->GroupAdd(
            Name    => $GroupName,
            Comment => $GroupsToCreate{$GroupName},
            ValidID => 1,
            UserID  => 1,
        );
        print "Created Group: $GroupName (ID: $GroupID)\n";
    } else {
        print "Group exists: $GroupName (ID: $GroupID)\n";
    }
    $GroupIDs{$GroupName} = $GroupID;
}

print "\n=== 2. CREATING ROLES (CATEGORIES AGENTS) ===\n";
my %RolesToCreate = (
    'Agent Agence'              => 'Agent de guichet et accueil agence',
    'Gestionnaire Paiements'     => 'Spécialiste monétique, cartes et virements',
    'Analyste Crédits'          => 'Gestionnaire contestations crédits et agios',
    'Officier Conformité'       => 'Expert conformité, fraude et réglementation',
    'Approbateur Réclamations'  => 'Chef de service et Directeur (Validation financière)',
);

my %RoleIDs;
for my $RoleName (keys %RolesToCreate) {
    my $RoleID = $GroupObject->RoleLookup( Role => $RoleName );
    if (!$RoleID) {
        $RoleID = $GroupObject->RoleAdd(
            Name    => $RoleName,
            Comment => $RolesToCreate{$RoleName},
            ValidID => 1,
            UserID  => 1,
        );
        print "Created Role: $RoleName (ID: $RoleID)\n";
    } else {
        print "Role exists: $RoleName (ID: $RoleID)\n";
    }
    $RoleIDs{$RoleName} = $RoleID;
}

print "\n=== 3. LINKING ROLES TO GROUPS ===\n";
my %RoleGroupMatrix = (
    'Agent Agence' => {
        'agences' => 'rw',
        'users'   => 'ro',
    },
    'Gestionnaire Paiements' => {
        'paiements' => 'rw',
        'agences'   => 'ro',
        'users'     => 'ro',
    },
    'Analyste Crédits' => {
        'credits' => 'rw',
        'users'   => 'ro',
    },
    'Officier Conformité' => {
        'conformite' => 'rw',
        'agences'    => 'ro',
        'paiements'  => 'ro',
        'credits'    => 'ro',
        'users'      => 'ro',
    },
    'Approbateur Réclamations' => {
        'approbateurs' => 'rw',
        'agences'      => 'rw',
        'paiements'    => 'rw',
        'credits'      => 'rw',
        'conformite'   => 'rw',
        'users'        => 'rw',
    },
);

for my $RoleName (keys %RoleGroupMatrix) {
    my $RoleID = $RoleIDs{$RoleName};
    next if !$RoleID;
    
    for my $GroupName (keys %{ $RoleGroupMatrix{$RoleName} }) {
        my $GroupID = $GroupObject->GroupLookup( Group => $GroupName );
        next if !$GroupID;
        
        my $Permission = $RoleGroupMatrix{$RoleName}{$GroupName};
        
        $GroupObject->PermissionGroupRoleAdd(
            GID        => $GroupID,
            RID        => $RoleID,
            Permission => { $Permission => 1 },
            UserID     => 1,
        );
        print "Linked Role '$RoleName' -> Group '$GroupName' ($Permission)\n";
    }
}

print "\n=== 4. ASSIGNING QUEUES TO DEDICATED GROUPS ===\n";
my %QueueGroupMapping = (
    'Agences'       => 'agences',
    'Paiements'     => 'paiements',
    'Mobile Money'  => 'paiements',
    'Crédits'       => 'credits',
    'Frais & Tarif' => 'credits',
    'Conformité'    => 'conformite',
    'Fraude'        => 'conformite',
    'Postmaster'    => 'agences',
    'Raw'           => 'agences',
    'Junk'          => 'agences',
    'Misc'          => 'agences',
);

for my $QueueName (keys %QueueGroupMapping) {
    my $QueueID = $QueueObject->QueueLookup( Queue => $QueueName );
    my $GroupName = $QueueGroupMapping{$QueueName};
    my $GroupID   = $GroupObject->GroupLookup( Group => $GroupName );
    
    if ($QueueID && $GroupID) {
        my %QueueData = $QueueObject->QueueGet( ID => $QueueID );
        $QueueObject->QueueUpdate(
            %QueueData,
            GroupID => $GroupID,
            UserID  => 1,
        );
        print "Queue '$QueueName' updated to Group '$GroupName' (ID: $GroupID)\n";
    }
}

print "\n=== 5. CREATING AGENT USERS & ASSIGNING ROLES ===\n";
my %AgentsToCreate = (
    'df@digitalfactory.sn' => {
        FirstName => 'Digital',
        LastName  => 'Factory',
        Email     => 'df@digitalfactory.sn',
        AllRoles  => 1,
    },
    'agent_agence' => {
        FirstName => 'Fatou',
        LastName  => 'Sarr',
        Email     => 'agent_agence@digitalfactory.sn',
        Role      => 'Agent Agence',
    },
    'agent_bo' => {
        FirstName => 'Ousmane',
        LastName  => 'Ndiaye',
        Email     => 'agent_bo@digitalfactory.sn',
        Role      => 'Gestionnaire Paiements',
    },
    'agent_checker' => {
        FirstName => 'Amadou',
        LastName  => 'Ba',
        Email     => 'agent_checker@digitalfactory.sn',
        Role      => 'Approbateur Réclamations',
    },
);

for my $Login (keys %AgentsToCreate) {
    my $Info = $AgentsToCreate{$Login};
    my $UID = $UserObject->UserLookup( UserLogin => $Login );
    if (!$UID) {
        $UID = $UserObject->UserAdd(
            UserLogin     => $Login,
            UserFirstname => $Info->{FirstName},
            UserLastname  => $Info->{LastName},
            UserPw        => 'password123',
            UserEmail     => $Info->{Email},
            ValidID       => 1,
            ChangeUserID  => 1,
        );
        print "Created Agent User: $Login (ID: $UID)\n";
    } else {
        print "Agent User exists: $Login (ID: $UID)\n";
    }
    
    if ($Info->{AllRoles}) {
        for my $RoleID (values %RoleIDs) {
            $GroupObject->PermissionRoleUserAdd(
                RID    => $RoleID,
                UID    => $UID,
                Active => 1,
                UserID => 1,
            );
        }
        print "Assigned ALL roles to agent '$Login' (ID: $UID)\n";
    } elsif ($Info->{Role}) {
        my $RoleID = $RoleIDs{ $Info->{Role} };
        if ($UID && $RoleID) {
            $GroupObject->PermissionRoleUserAdd(
                RID    => $RoleID,
                UID    => $UID,
                Active => 1,
                UserID => 1,
            );
            print "Assigned Role '$Info->{Role}' to Agent '$Login' (ID: $UID)\n";
        }
    }
}

print "\n=== RBAC CONFIGURATION COMPLETED SUCCESSFULLY! ===\n";
