# --
# Kernel/Config/Files/User/ZZZAResolve360.pm - Custom configuration for Résolve360
# --

package Kernel::Config::Files::User::ZZZAResolve360;

use strict;
use warnings;
use utf8;

sub Load {
    my $Self = shift;

    # Core Branding
    $Self->{'ProductName'} = 'Résolve360';
    $Self->{'NotificationSenderName'} = 'Résolve360 Notifications';
    $Self->{'NotificationSenderEmail'} = 'support@digitalfactory.sn';
    $Self->{'NotificationSubjectLostPassword'} = 'Nouveau mot de passe - Résolve360';
    $Self->{'NotificationSubjectLostPasswordToken'} = 'Demande de réinitialisation de mot de passe - Résolve360';

    # Global Default Language
    $Self->{'DefaultLanguage'} = 'fr';
    $Self->{'CustomerDefaultLanguage'} = 'fr';

    # Security & White-labeling
    $Self->{'Secure::DisableBanner'} = 1;

    # Disable OTOBO default dashboard widgets
    $Self->{'DashboardBackend'}->{'0200-Image'}->{'Default'} = 0;
    $Self->{'DashboardBackend'}->{'0300-IFrame'}->{'Default'} = 0;
    $Self->{'DashboardBackend'}->{'0405-News'}->{'Default'} = 0;
    $Self->{'DashboardBackend'}->{'0410-RSS'}->{'Default'} = 0;

    return 1;
}

1;
