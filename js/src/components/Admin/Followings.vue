<template>
    <div>
        <form @submit="followRelay">
            <b-field :label="$t('Add an instance')" custom-class="add-relay" horizontal>
                <b-field grouped expanded size="is-large">
                    <p class="control">
                        <b-input v-model="newRelayAddress" :placeholder="$t('Ex: test.mobilizon.org')" />
                    </p>
                    <p class="control">
                        <b-button type="is-primary" native-type="submit">{{ $t('Add an instance') }}</b-button>
                    </p>
                </b-field>
            </b-field>
        </form>
        <b-table
                v-show="relayFollowings.elements.length > 0"
                :data="relayFollowings.elements"
                :loading="$apollo.queries.relayFollowings.loading"
                ref="table"
                :checked-rows.sync="checkedRows"
                :is-row-checkable="(row) => row.id !== 3"
                detailed
                :show-detail-icon="false"
                paginated
                backend-pagination
                :total="relayFollowings.total"
                :per-page="perPage"
                @page-change="onPageChange"
                checkable
                checkbox-position="left">
            <template slot-scope="props">
                <b-table-column field="targetActor.id" label="ID" width="40" numeric>
                    {{ props.row.targetActor.id }}
                </b-table-column>

                <b-table-column field="targetActor.type" :label="$t('Type')" width="80">
                    <b-icon icon="lan" v-if="isInstance(props.row.targetActor)" />
                    <b-icon icon="account-circle" v-else />
                </b-table-column>

                <b-table-column field="approved" :label="$t('Status')" width="100" sortable centered>
                                <span :class="`tag ${props.row.approved ? 'is-success' : 'is-danger' }`">
                                   {{ props.row.approved ? $t('Accepted') : $t('Pending') }}
                                </span>
                </b-table-column>

                <b-table-column field="targetActor.domain" :label="$t('Domain')" sortable>
                    <template>
                        <a @click="toggle(props.row)" v-if="isInstance(props.row.targetActor)">
                            {{ props.row.targetActor.domain }}
                        </a>
                        <a @click="toggle(props.row)" v-else>
                            {{ `${props.row.targetActor.preferredUsername}@${props.row.targetActor.domain}` }}
                        </a>
                    </template>
                </b-table-column>

                <b-table-column field="targetActor.updatedAt" :label="$t('Date')" sortable>
                    {{ props.row.updatedAt | formatDateTimeString }}
                </b-table-column>
            </template>

            <template slot="detail" slot-scope="props">
                <article>
                    <div class="content">
                        <strong>{{ props.row.targetActor.domain }}</strong>
                        <small>@{{ props.row.targetActor.preferredUsername }}</small>
                        <small>31m</small>
                        <br>
                        <p v-html="props.row.targetActor.summary" />
                    </div>
                </article>
            </template>

            <template slot="bottom-left" v-if="checkedRows.length > 0">
                <b-button @click="removeRelays" type="is-danger">
                    {{ $tc('No instance to remove|Remove instance|Remove {number} instances', checkedRows.length, { number: checkedRows.length }) }}
                </b-button>
            </template>
        </b-table>
        <b-message type="is-danger" v-if="relayFollowings.elements.length === 0">
            {{ $t("You don't follow any instances yet.") }}
        </b-message>
    </div>
</template>
<script lang="ts">
import { Component, Mixins } from 'vue-property-decorator';
import { ADD_RELAY, RELAY_FOLLOWINGS, REMOVE_RELAY } from '@/graphql/admin';
import { IFollower } from '@/types/actor/follower.model';
import { Paginate } from '@/types/paginate';
import RelayMixin from '@/mixins/relay';

@Component({
  apollo: {
    relayFollowings: {
      query: RELAY_FOLLOWINGS,
      fetchPolicy: 'cache-and-network',
    },
  },
  metaInfo() {
    return {
      title: this.$t('Followings') as string,
      titleTemplate: '%s | Mobilizon',
    };
  },
})
export default class Followings extends Mixins(RelayMixin) {

  relayFollowings: Paginate<IFollower> = { elements: [], total: 0 };
  newRelayAddress: String = '';

  async followRelay(e) {
    e.preventDefault();
    await this.$apollo.mutate({
      mutation: ADD_RELAY,
      variables: {
        address: this.newRelayAddress,
      },
            // TODO: Handle cache update properly without refreshing
    });
    await this.$apollo.queries.relayFollowings.refetch();
    this.newRelayAddress = '';
  }

  async removeRelays() {
    await this.checkedRows.forEach((row: IFollower) => {
      this.removeRelay(`${row.targetActor.preferredUsername}@${row.targetActor.domain}`);
    });
  }

  async removeRelay(address: String) {
    await this.$apollo.mutate({
      mutation: REMOVE_RELAY,
      variables: {
        address,
      },
    });
    await this.$apollo.queries.relayFollowings.refetch();
    this.checkedRows = [];
  }
}
</script>