export type Envs = "test" | "development" | "staging" | "production";

export type ConfigProps = {
  APP_NAME: string;
};

export const getConfig = (env: Envs = "development"): ConfigProps => ({
  APP_NAME: `${env}/BusinessFarm`
})
